class Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :recent, -> { order(updated_at: :desc) }

  def last_message
    messages.order(created_at: :desc).first
  end

  def message_count
    messages.count
  end
end
