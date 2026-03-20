class CreateFrames < ActiveRecord::Migration[8.1]
  def change
    create_table :frames do |t|
      t.references :video_learning, null: false, foreign_key: true
      t.float :timestamp_seconds
      t.integer :position

      t.timestamps
    end
  end
end
