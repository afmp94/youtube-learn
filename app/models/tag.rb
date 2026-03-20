class Tag < ApplicationRecord
  has_many :video_learning_tags, dependent: :destroy
  has_many :video_learnings, through: :video_learning_tags

  validates :name, presence: true, uniqueness: true

  normalizes :name, with: ->(n) { n.strip.downcase }

  scope :popular, -> { left_joins(:video_learning_tags).group(:id).order("COUNT(video_learning_tags.id) DESC") }
end
