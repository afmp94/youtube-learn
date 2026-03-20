class ExtractQuotesJob < ApplicationJob
  queue_as :default

  def perform(video_learning_id)
    video_learning = VideoLearning.find(video_learning_id)

    return unless video_learning.completed?
    return unless video_learning.transcript_text.present?

    Quotes::Extractor.new(video_learning).call

    Rails.logger.info("Extracted #{video_learning.quotes.count} quotes for VideoLearning ##{video_learning.id}")
  rescue Quotes::ExtractionError => e
    Rails.logger.error("Quote extraction failed for VideoLearning ##{video_learning_id}: #{e.message}")
  rescue => e
    Rails.logger.error("Unexpected error extracting quotes for VideoLearning ##{video_learning_id}: #{e.class} - #{e.message}")
  end
end
