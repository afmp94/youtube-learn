class ChangeEmbeddingDimensions < ActiveRecord::Migration[8.1]
  def up
    # Drop HNSW index first
    remove_index :video_learnings, name: :index_video_learnings_on_embedding, if_exists: true

    # Change from 1536 (OpenAI) to 768 (nomic-embed-text via Ollama)
    remove_column :video_learnings, :embedding
    add_column :video_learnings, :embedding, :vector, limit: 768

    # Recreate HNSW index for 768 dims
    execute <<-SQL
      CREATE INDEX index_video_learnings_on_embedding
      ON video_learnings
      USING hnsw (embedding vector_cosine_ops)
      WITH (m = 16, ef_construction = 64);
    SQL
  end

  def down
    remove_index :video_learnings, name: :index_video_learnings_on_embedding, if_exists: true
    remove_column :video_learnings, :embedding
    add_column :video_learnings, :embedding, :vector, limit: 1536

    execute <<-SQL
      CREATE INDEX index_video_learnings_on_embedding
      ON video_learnings
      USING hnsw (embedding vector_cosine_ops)
      WITH (m = 16, ef_construction = 64);
    SQL
  end
end
