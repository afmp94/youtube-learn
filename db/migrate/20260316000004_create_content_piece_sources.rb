class CreateContentPieceSources < ActiveRecord::Migration[8.1]
  def change
    create_table :content_piece_sources do |t|
      t.references :content_piece, null: false, foreign_key: true
      t.references :video_learning, null: false, foreign_key: true

      t.timestamps
    end

    add_index :content_piece_sources, [:content_piece_id, :video_learning_id],
              unique: true, name: "idx_content_piece_sources_unique"
  end
end
