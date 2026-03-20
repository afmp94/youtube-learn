module Imports
  class PlaylistExtractor
    def initialize(source_url)
      @source_url = source_url
    end

    def call
      output = run_yt_dlp
      parse_output(output)
    end

    private

    def run_yt_dlp
      stdout, stderr, status = Open3.capture3(
        "yt-dlp", "--flat-playlist", "--dump-json", "--no-download", @source_url
      )

      unless status.success?
        if stderr.include?("is not a valid URL") || stderr.include?("Unsupported URL")
          raise ExtractionError, "Invalid playlist URL. Please provide a valid YouTube playlist URL."
        elsif stderr.include?("Private") || stderr.include?("unavailable")
          raise ExtractionError, "This playlist is private or unavailable."
        else
          raise ExtractionError, "Failed to extract playlist: #{stderr.truncate(300)}"
        end
      end

      if stdout.blank?
        raise ExtractionError, "No videos found in this playlist. It may be empty or private."
      end

      stdout
    end

    def parse_output(output)
      videos = []

      output.each_line do |line|
        next if line.blank?

        begin
          data = JSON.parse(line)
          video_id = data["id"]
          next if video_id.blank?

          videos << {
            id: video_id,
            title: data["title"] || "Untitled",
            url: data["url"] || "https://www.youtube.com/watch?v=#{video_id}"
          }
        rescue JSON::ParserError
          next
        end
      end

      if videos.empty?
        raise ExtractionError, "Could not parse any videos from the playlist."
      end

      videos
    end
  end
end
