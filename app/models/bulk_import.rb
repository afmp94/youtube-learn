class BulkImport < ApplicationRecord
  belongs_to :user
  has_many :video_learnings, dependent: :nullify

  enum :import_type, { playlist: 0, channel_import: 1 }
  enum :status, { pending: 0, extracting_urls: 1, processing: 2, completed: 3, failed: 4 }

  validates :source_url, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def progress_percentage
    return 0 if total_count.zero?
    ((processed_count.to_f / total_count) * 100).round
  end

  def increment_processed!
    increment!(:processed_count)
  end
end
