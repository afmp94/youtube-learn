class CreateBulkImports < ActiveRecord::Migration[8.1]
  def change
    create_table :bulk_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source_url, null: false
      t.integer :import_type, default: 0, null: false
      t.string :title
      t.integer :total_count, default: 0, null: false
      t.integer :processed_count, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.jsonb :video_urls, default: []

      t.timestamps
    end

    add_index :bulk_imports, [:user_id, :status]
  end
end
