class Message < ApplicationRecord
  belongs_to :conversation

  enum :role, { user: 0, assistant: 1 }

  validates :content, presence: true
  validates :role, presence: true

  def source_videos
    return VideoLearning.none if source_video_ids.blank?
    VideoLearning.where(id: source_video_ids)
  end

  def has_sources?
    source_video_ids.present? && source_video_ids.any?
  end
end
