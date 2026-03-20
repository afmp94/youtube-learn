class KnowledgeEntry < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_one_attached :file

  enum :entry_type, { note: 0, article: 1, link: 2, file_upload: 3, idea: 4 }

  validates :entry_type, presence: true
  validates :title, presence: true
  validates :body, presence: true, unless: -> { file_upload? }
  validates :source_url, presence: true, if: -> { link? }

  scope :recent, -> { order(created_at: :desc) }
end
