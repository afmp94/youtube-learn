module Imports
  class BulkImportService
    def initialize(bulk_import)
      @bulk_import = bulk_import
      @user = bulk_import.user
    end

    def call
      extract_urls
      process_videos
      mark_completed
    rescue Imports::ExtractionError => e
      mark_failed(e.message)
    rescue => e
      mark_failed("Unexpected error: #{e.message}")
      Rails.logger.error("BulkImportService failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    end

    private

    def extract_urls
      @bulk_import.update!(status: :extracting_urls)
      broadcast_progress

      videos = PlaylistExtractor.new(@bulk_import.source_url).call

      @bulk_import.update!(
        video_urls: videos,
        total_count: videos.size,
        title: @bulk_import.title.presence || playlist_title_from(videos)
      )

      broadcast_progress
    end

    def process_videos
      @bulk_import.update!(status: :processing)
      broadcast_progress

      @bulk_import.video_urls.each_with_index do |video_info, index|
        video_id = video_info["id"]
        video_url = video_info["url"]
        video_url = "https://www.youtube.com/watch?v=#{video_id}" if video_url.blank? || !video_url.start_with?("http")

        # Skip if user already has this video
        if @user.video_learnings.exists?(youtube_video_id: video_id)
          @bulk_import.increment_processed!
          broadcast_progress
          next
        end

        begin
          video_learning = @user.video_learnings.create!(
            youtube_url: video_url,
            youtube_video_id: video_id,
            title: video_info["title"],
            bulk_import: @bulk_import
          )

          ProcessVideoJob.perform_later(video_learning.id)
        rescue ActiveRecord::RecordInvalid => e
          # Skip duplicates or invalid records gracefully
          Rails.logger.warn("BulkImport #{@bulk_import.id}: Skipped video #{video_id} - #{e.message}")
        end

        @bulk_import.increment_processed!
        broadcast_progress
      end
    end

    def mark_completed
      @bulk_import.update!(status: :completed)
      broadcast_progress
    end

    def mark_failed(message)
      @bulk_import.update!(status: :failed, error_message: message)
      broadcast_progress
    end

    def broadcast_progress
      Turbo::StreamsChannel.broadcast_replace_to(
        "bulk_import_#{@bulk_import.id}",
        target: "import_progress",
        partial: "bulk_imports/progress",
        locals: { bulk_import: @bulk_import }
      )
    end

    def playlist_title_from(videos)
      "Playlist Import (#{videos.size} videos)"
    end
  end
end
