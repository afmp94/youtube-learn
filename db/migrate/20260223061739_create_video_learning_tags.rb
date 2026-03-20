class CreateVideoLearningTags < ActiveRecord::Migration[8.1]
  def change
    create_table :video_learning_tags do |t|
      t.references :video_learning, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :video_learning_tags, [:video_learning_id, :tag_id], unique: true
  end
end
