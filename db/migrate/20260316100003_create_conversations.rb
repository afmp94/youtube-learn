class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end

    add_index :conversations, [:user_id, :created_at]
  end
end
