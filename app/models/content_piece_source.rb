class ContentPieceSource < ApplicationRecord
  belongs_to :content_piece
  belongs_to :video_learning

  validates :video_learning_id, uniqueness: { scope: :content_piece_id }
end
