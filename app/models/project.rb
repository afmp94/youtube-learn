class Project < ApplicationRecord
  belongs_to :user
  has_many :knowledge_entries, dependent: :destroy
  has_many :project_video_learnings, dependent: :destroy
  has_many :video_learnings, through: :project_video_learnings
  has_many :content_pieces, dependent: :nullify
  has_many :conversations, dependent: :nullify

  enum :status, { active: 0, archived: 1 }

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :recent, -> { order(updated_at: :desc) }
  scope :active, -> { where(status: :active) }

  def video_count
    video_learnings.count
  end

  def knowledge_count
    knowledge_entries.count
  end

  def content_count
    content_pieces.count
  end
end
