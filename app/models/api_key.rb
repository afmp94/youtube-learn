class ApiKey < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.authenticate(token)
    return nil if token.blank?
    digest = Digest::SHA256.hexdigest(token)
    key = active.find_by(token_digest: digest)
    key&.touch(:last_used_at)
    key
  end

  def self.generate_token
    SecureRandom.hex(32)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end
end
