class Quote < ApplicationRecord
  belongs_to :video_learning

  validates :text, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_speaker, ->(speaker) { where(speaker: speaker) }

  def youtube_timestamp_url
    return nil unless video_learning.youtube_video_id.present? && timestamp_seconds.present?
    "https://www.youtube.com/watch?v=#{video_learning.youtube_video_id}&t=#{timestamp_seconds.to_i}"
  end

  def formatted_timestamp
    return nil unless timestamp_seconds
    minutes = (timestamp_seconds / 60).to_i
    seconds = (timestamp_seconds % 60).to_i
    format("%d:%02d", minutes, seconds)
  end
end
