class ProjectVideoLearning < ApplicationRecord
  belongs_to :project
  belongs_to :video_learning

  validates :video_learning_id, uniqueness: { scope: :project_id }

  scope :ordered, -> { order(:position, :created_at) }
end
