class ProcessVideoJob < ApplicationJob
  queue_as :default

  def perform(video_learning_id, skip_frames: false)
    vl = VideoLearning.find(video_learning_id)

    begin
      update_progress(vl, :extracting, 5, "Fetching video metadata...")
      Videos::MetadataExtractor.new(vl).call
      update_progress(vl, :extracting, 10, "Metadata extracted")

      update_progress(vl, :extracting, 15, "Extracting transcript...")
      Videos::TranscriptExtractor.new(vl).call
      update_progress(vl, :extracting, 30, "Transcript extracted")

      unless skip_frames
        update_progress(vl, :extracting, 35, "Downloading video and extracting frames...")
        Videos::FrameExtractor.new(vl).call
        update_progress(vl, :extracting, 60, "Frames extracted")
      end

      update_progress(vl, :analyzing, 70, "Analyzing with Claude AI...")
      Videos::ClaudeAnalyzer.new(vl).call
      update_progress(vl, :analyzing, 90, "Analysis complete")

      # Apply suggested tags if available
      if vl.concepts.present?
        suggested = vl.concepts.map { |c| c["name"] }.compact.first(5)
        vl.tag_list = suggested if suggested.any?
      end

      # Auto-assign channel (expert profile)
      Channels::AutoAssign.new(vl).call rescue nil

      update_progress(vl, :completed, 100, "Done!")

      # Auto-extract quotes in background
      ExtractQuotesJob.perform_later(vl.id)

      # Generate embedding for semantic search
      GenerateEmbeddingJob.perform_later("VideoLearning", vl.id)

    rescue Videos::VideoUnavailableError => e
      handle_failure(vl, e.message)
    rescue Videos::Error => e
      handle_failure(vl, e.message)
    rescue => e
      handle_failure(vl, "Unexpected error: #{e.message}")
      Rails.logger.error("ProcessVideoJob failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    end
  end

  private

  def update_progress(vl, status, progress, message)
    vl.update!(status: status, processing_progress: progress, error_message: nil)
    broadcast_progress(vl, message)
  end

  def handle_failure(vl, message)
    vl.update!(status: :failed, error_message: message)
    broadcast_progress(vl, message)
  end

  def broadcast_progress(vl, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "video_learning_#{vl.id}",
      target: "progress_bar",
      partial: "video_learnings/progress_bar",
      locals: { video_learning: vl, message: message }
    )

    if vl.completed? || vl.failed?
      Turbo::StreamsChannel.broadcast_replace_to(
        "video_learning_#{vl.id}",
        target: "video_learning_content",
        partial: "video_learnings/content",
        locals: { video_learning: vl }
      )
    end
  end
end
