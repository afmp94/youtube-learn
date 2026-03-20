class AddHnswIndexToVideoLearnings < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE INDEX index_video_learnings_on_embedding
      ON video_learnings
      USING hnsw (embedding vector_cosine_ops)
      WITH (m = 16, ef_construction = 64);
    SQL
  end

  def down
    remove_index :video_learnings, name: :index_video_learnings_on_embedding
  end
end
