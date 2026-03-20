class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.integer :role, null: false
      t.text :content, null: false
      t.jsonb :source_video_ids, default: []

      t.timestamps
    end
  end
end
