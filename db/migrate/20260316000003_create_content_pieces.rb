class CreateContentPieces < ActiveRecord::Migration[8.1]
  def change
    create_table :content_pieces do |t|
      t.references :user, null: false, foreign_key: true
      t.references :collection, foreign_key: true
      t.integer :platform, null: false
      t.integer :content_format, null: false
      t.string :title
      t.text :body
      t.integer :status, default: 0, null: false
      t.string :template_name
      t.text :generation_prompt

      t.timestamps
    end

    add_index :content_pieces, [:user_id, :status]
    add_index :content_pieces, [:user_id, :platform]
  end
end
