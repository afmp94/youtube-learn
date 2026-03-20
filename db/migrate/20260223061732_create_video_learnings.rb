class CreateVideoLearnings < ActiveRecord::Migration[8.1]
  def change
    create_table :video_learnings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :youtube_video_id
      t.string :youtube_url
      t.string :title
      t.string :channel_name
      t.text :description
      t.integer :duration_seconds
      t.string :thumbnail_url
      t.datetime :published_at
      t.text :transcript_text
      t.jsonb :transcript_data
      t.integer :status, default: 0, null: false
      t.integer :processing_progress, default: 0, null: false
      t.text :error_message
      t.text :summary
      t.jsonb :key_takeaways
      t.jsonb :concepts
      t.text :detailed_notes
      t.string :difficulty_level
      t.integer :estimated_read_time

      t.timestamps
    end

    add_index :video_learnings, [:user_id, :youtube_video_id], unique: true
    add_index :video_learnings, :status
  end
end
