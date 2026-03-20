class CreateCollectionVideoLearnings < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_video_learnings do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :video_learning, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :collection_video_learnings, [:collection_id, :video_learning_id],
              unique: true, name: "idx_collection_video_learnings_unique"
  end
end
