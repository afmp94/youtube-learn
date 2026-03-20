class BulkImportJob < ApplicationJob
  queue_as :default

  def perform(bulk_import_id)
    bulk_import = BulkImport.find(bulk_import_id)
    Imports::BulkImportService.new(bulk_import).call
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("BulkImportJob: BulkImport #{bulk_import_id} not found")
  rescue => e
    if bulk_import
      bulk_import.update!(status: :failed, error_message: "Job failed: #{e.message}")
    end
    Rails.logger.error("BulkImportJob failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
  end
end
