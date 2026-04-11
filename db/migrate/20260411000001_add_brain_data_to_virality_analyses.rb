class AddBrainDataToViralityAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :virality_analyses, :brain_data, :jsonb, default: {}
    add_column :virality_analyses, :brain_status, :integer, default: 0
    add_column :virality_analyses, :brain_error_message, :text
  end
end
