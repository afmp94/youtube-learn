class AddProjectToContentPiecesAndConversations < ActiveRecord::Migration[8.1]
  def change
    add_reference :content_pieces, :project, foreign_key: true
    add_reference :conversations, :project, foreign_key: true
  end
end
