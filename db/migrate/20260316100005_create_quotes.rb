class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.references :video_learning, null: false, foreign_key: true
      t.text :text, null: false
      t.string :speaker
      t.float :timestamp_seconds
      t.text :context

      t.timestamps
    end

    add_index :quotes, [:video_learning_id, :timestamp_seconds]
  end
end
