class AddEmbeddingsToVideoLearnings < ActiveRecord::Migration[8.1]
  def change
    add_column :video_learnings, :embedding, :vector, limit: 1536
    add_column :video_learnings, :embedding_generated_at, :datetime
  end
end
