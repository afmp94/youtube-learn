class CreateChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :channels do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :youtube_channel_id
      t.text :description
      t.string :thumbnail_url
      t.text :notes

      t.timestamps
    end

    add_index :channels, [:user_id, :name], unique: true
    add_index :channels, [:user_id, :youtube_channel_id], unique: true, where: "youtube_channel_id IS NOT NULL"

    add_reference :video_learnings, :channel, foreign_key: true
  end
end
