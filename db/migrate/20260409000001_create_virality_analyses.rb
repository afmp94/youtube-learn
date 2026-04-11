class CreateViralityAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :virality_analyses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :analyzable_type
      t.bigint :analyzable_id
      t.integer :input_type, null: false, default: 0
      t.string :title
      t.text :input_text
      t.string :target_platform
      t.integer :overall_score
      t.jsonb :dimension_scores, default: {}
      t.jsonb :dimension_details, default: {}
      t.text :strengths
      t.text :improvements
      t.text :overall_assessment
      t.integer :status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :virality_analyses, [:user_id, :created_at]
    add_index :virality_analyses, [:user_id, :status]
    add_index :virality_analyses, [:analyzable_type, :analyzable_id]
  end
end
