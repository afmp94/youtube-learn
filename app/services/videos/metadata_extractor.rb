module Videos
  class MetadataExtractor
    def initialize(video_learning)
      @video_learning = video_learning
    end

    def call
      url = @video_learning.youtube_url
      output = run_yt_dlp(url)
      data = JSON.parse(output)

      @video_learning.update!(
        title: data["title"],
        channel_name: data["uploader"] || data["channel"],
        description: data["description"]&.truncate(5000),
        duration_seconds: data["duration"],
        thumbnail_url: data["thumbnail"],
        published_at: parse_date(data["upload_date"]),
        youtube_video_id: data["id"]
      )

      data
    rescue JSON::ParserError => e
      raise MetadataError, "Failed to parse video metadata: #{e.message}"
    end

    private

    def run_yt_dlp(url)
      stdout, stderr, status = Open3.capture3(
        "yt-dlp", "--dump-json", "--no-download", url
      )

      unless status.success?
        if stderr.include?("Private video") || stderr.include?("Video unavailable")
          raise VideoUnavailableError, "Video is private or unavailable"
        end
        raise MetadataError, "yt-dlp metadata extraction failed: #{stderr.truncate(500)}"
      end

      stdout
    end

    def parse_date(date_str)
      return nil if date_str.blank?
      Date.strptime(date_str, "%Y%m%d")
    rescue Date::Error
      nil
    end
  end
end
