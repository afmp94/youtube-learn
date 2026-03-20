class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_video_learnings, dependent: :destroy
  has_many :video_learnings, through: :collection_video_learnings
  has_many :content_pieces, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :recent, -> { order(created_at: :desc) }

  def video_count
    video_learnings.count
  end

  def completed_video_count
    video_learnings.completed.count
  end
end
