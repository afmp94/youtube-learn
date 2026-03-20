class VideoLearningTag < ApplicationRecord
  belongs_to :video_learning
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :video_learning_id }
end
