class CreateKnowledgeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_entries do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :entry_type, null: false, default: 0
      t.string :title
      t.text :body
      t.string :source_url
      t.text :summary
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :knowledge_entries, [:project_id, :entry_type]
    add_index :knowledge_entries, [:user_id, :created_at]
  end
end
