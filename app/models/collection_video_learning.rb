class CollectionVideoLearning < ApplicationRecord
  belongs_to :collection
  belongs_to :video_learning

  validates :video_learning_id, uniqueness: { scope: :collection_id }

  scope :ordered, -> { order(:position, :created_at) }
end
