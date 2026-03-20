class CreateProjectVideoLearnings < ActiveRecord::Migration[8.1]
  def change
    create_table :project_video_learnings do |t|
      t.references :project, null: false, foreign_key: true
      t.references :video_learning, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :project_video_learnings, [:project_id, :video_learning_id],
              unique: true, name: "idx_project_video_learnings_unique"
  end
end
