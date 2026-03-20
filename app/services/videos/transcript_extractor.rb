module Videos
  class TranscriptExtractor
    def initialize(video_learning)
      @video_learning = video_learning
    end

    def call
      transcript = fetch_with_gem || fetch_with_yt_dlp

      if transcript.blank?
        Rails.logger.warn("No transcript available for #{@video_learning.youtube_video_id}")
        @video_learning.update!(transcript_text: "", transcript_data: [])
        return
      end

      @video_learning.update!(
        transcript_text: transcript.map { |s| s[:text] }.join(" "),
        transcript_data: transcript
      )
    end

    private

    def fetch_with_gem
      video_id = @video_learning.youtube_video_id
      return nil if video_id.blank?

      transcript = YouTubeTranscript::Transcript.fetch(video_id)
      transcript.map do |segment|
        {
          text: segment["text"],
          start: segment["start"],
          duration: segment["dur"] || segment["duration"]
        }
      end
    rescue => e
      Rails.logger.info("youtube-transcript-rb failed: #{e.message}, trying yt-dlp fallback")
      nil
    end

    def fetch_with_yt_dlp
      url = @video_learning.youtube_url
      Dir.mktmpdir do |dir|
        subtitle_file = File.join(dir, "subs")
        stdout, stderr, status = Open3.capture3(
          "yt-dlp",
          "--skip-download",
          "--write-auto-sub",
          "--sub-lang", "en",
          "--sub-format", "json3",
          "--output", subtitle_file,
          url
        )

        json_file = Dir.glob(File.join(dir, "*.json3")).first
        return nil unless json_file && File.exist?(json_file)

        data = JSON.parse(File.read(json_file))
        events = data["events"] || []

        events.filter_map do |event|
          next unless event["segs"]
          text = event["segs"].map { |s| s["utf8"] }.join.strip
          next if text.blank?

          {
            text: text,
            start: (event["tStartMs"].to_f / 1000).round(2),
            duration: ((event["dDurationMs"] || 0).to_f / 1000).round(2)
          }
        end
      end
    rescue => e
      Rails.logger.error("yt-dlp transcript fallback failed: #{e.message}")
      nil
    end
  end
end
