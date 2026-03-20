class Channel < ApplicationRecord
  belongs_to :user
  has_many :video_learnings, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_video_count, -> {
    left_joins(:video_learnings)
      .group(:id)
      .order(Arel.sql("COUNT(video_learnings.id) DESC"))
  }

  def video_count
    video_learnings.count
  end

  def completed_video_count
    video_learnings.completed.count
  end

  def top_concepts(limit = 10)
    video_learnings.completed
      .where.not(concepts: nil)
      .pluck(:concepts)
      .flatten
      .group_by { |c| c["name"] }
      .sort_by { |_, v| -v.size }
      .first(limit)
      .map { |name, occurrences| { name: name, count: occurrences.size } }
  end
end
