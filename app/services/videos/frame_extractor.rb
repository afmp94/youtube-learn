module Videos
  class FrameExtractor
    MAX_FRAMES = 20
    FRAME_INTERVAL = 30 # seconds

    def initialize(video_learning)
      @video_learning = video_learning
    end

    def call
      duration = @video_learning.duration_seconds || 300
      interval = [FRAME_INTERVAL, (duration.to_f / MAX_FRAMES).ceil].max
      frame_count = [duration / interval, MAX_FRAMES].min

      return if frame_count <= 0

      Dir.mktmpdir("frames") do |dir|
        download_and_extract(dir, interval)
        attach_frames(dir)
      end
    end

    private

    def download_and_extract(dir, interval)
      url = @video_learning.youtube_url
      video_file = File.join(dir, "video.mp4")

      # Download video at 720p max
      stdout, stderr, status = Open3.capture3(
        "yt-dlp",
        "-f", "bestvideo[height<=720]+bestaudio/best[height<=720]/best",
        "--merge-output-format", "mp4",
        "-o", video_file,
        url
      )

      unless status.success? && File.exist?(video_file)
        raise FrameExtractionError, "Video download failed: #{stderr.truncate(500)}"
      end

      # Extract frames with ffmpeg
      output_pattern = File.join(dir, "frame_%04d.jpg")
      stdout, stderr, status = Open3.capture3(
        "ffmpeg",
        "-i", video_file,
        "-vf", "fps=1/#{interval},scale=1280:-2",
        "-q:v", "2",
        "-frames:v", MAX_FRAMES.to_s,
        output_pattern
      )

      unless status.success?
        raise FrameExtractionError, "Frame extraction failed: #{stderr.truncate(500)}"
      end
    end

    def attach_frames(dir)
      frame_files = Dir.glob(File.join(dir, "frame_*.jpg")).sort

      frame_files.each_with_index do |file, index|
        duration = @video_learning.duration_seconds || 300
        interval = [FRAME_INTERVAL, (duration.to_f / MAX_FRAMES).ceil].max
        timestamp = index * interval

        frame = @video_learning.frames.create!(
          timestamp_seconds: timestamp,
          position: index + 1
        )

        frame.image.attach(
          io: File.open(file),
          filename: "frame_#{format('%04d', index + 1)}.jpg",
          content_type: "image/jpeg"
        )
      end
    end
  end
end
