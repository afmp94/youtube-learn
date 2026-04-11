class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :video_learnings, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :content_pieces, dependent: :destroy
  has_many :channels, dependent: :destroy
  has_many :bulk_imports, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :knowledge_entries, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :virality_analyses, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
