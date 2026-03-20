class AddBulkImportToVideoLearnings < ActiveRecord::Migration[8.1]
  def change
    add_reference :video_learnings, :bulk_import, null: true, foreign_key: true
  end
end
