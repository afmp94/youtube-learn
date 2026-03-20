class Frame < ApplicationRecord
  belongs_to :video_learning
  has_one_attached :image

  validates :timestamp_seconds, presence: true
  validates :position, presence: true

  scope :ordered, -> { order(:position) }

  def formatted_timestamp
    minutes = (timestamp_seconds / 60).floor
    seconds = (timestamp_seconds % 60).floor
    format("%d:%02d", minutes, seconds)
  end
end
