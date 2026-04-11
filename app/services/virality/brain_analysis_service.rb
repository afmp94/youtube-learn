require "open3"

module Virality
  class BrainAnalysisService
    def initialize(analysis:)
      @analysis = analysis
    end

    def call
      return skip_result unless can_analyze?

      input_args = build_input_args
      return skip_result if input_args.nil?

      Dir.mktmpdir("tribe") do |output_dir|
        result = run_tribe(input_args, output_dir)

        if result["status"] == "error"
          raise Virality::Error, result["error"].to_s.truncate(500)
        end

        attach_brain_images(output_dir, result)
        { brain_data: result }
      end
    end

    private

    def can_analyze?
      config = Rails.application.config.tribe
      return false unless config.enabled

      python_path = config.python_path
      script_path = config.script_path

      File.exist?(python_path) && File.exist?(script_path)
    end

    def build_input_args
      text = @analysis.input_text
      return nil if text.blank?

      # For video_learning with an actual video file, we could use --video
      # For now, all inputs use text (TRIBE converts to TTS internally)
      ["--text", text.truncate(5000)]
    end

    def run_tribe(input_args, output_dir)
      config = Rails.application.config.tribe

      env = {
        "PYTORCH_ENABLE_MPS_FALLBACK" => "1",
        "PYTHONPATH" => ""
      }

      cmd = [
        config.python_path,
        config.script_path,
        *input_args,
        "--output-dir", output_dir,
        "--cache-folder", config.cache_folder
      ]

      stdout, stderr, status = Open3.capture3(env, *cmd, chdir: Rails.root.to_s)

      Rails.logger.info("TRIBE v2 stderr: #{stderr.truncate(500)}") if stderr.present?

      unless status.success?
        # Try to parse error JSON from stdout
        begin
          return JSON.parse(stdout)
        rescue JSON::ParserError
          raise Virality::Error, "TRIBE v2 process failed (exit #{status.exitstatus}): #{stderr.truncate(500)}"
        end
      end

      JSON.parse(stdout)
    rescue JSON::ParserError => e
      raise Virality::Error, "Failed to parse TRIBE v2 output: #{e.message}"
    end

    def attach_brain_images(output_dir, result)
      (result["brain_images"] || {}).each do |view_name, filename|
        path = File.join(output_dir, filename)
        next unless File.exist?(path)

        @analysis.brain_images.attach(
          io: File.open(path),
          filename: "brain_#{view_name}.png",
          content_type: "image/png"
        )
      end
    end

    def skip_result
      { brain_data: {}, skipped: true }
    end
  end
end
