class ContentPiece < ApplicationRecord
  belongs_to :user
  belongs_to :collection, optional: true
  belongs_to :project, optional: true
  has_many :content_piece_sources, dependent: :destroy
  has_many :video_learnings, through: :content_piece_sources

  enum :status, { draft: 0, review: 1, published: 2 }
  enum :platform, { linkedin: 0, twitter: 1, youtube_script: 2, blog: 3, newsletter: 4 }
  enum :content_format, { post: 0, thread: 1, script: 2, carousel_outline: 3, article: 4, hooks_list: 5 }

  validates :platform, presence: true
  validates :content_format, presence: true
  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :by_status, ->(status) { where(status: status) }

  def platform_icon
    case platform
    when "linkedin" then "linkedin"
    when "twitter" then "twitter"
    when "youtube_script" then "youtube"
    when "blog" then "document"
    when "newsletter" then "email"
    end
  end

  def platform_label
    case platform
    when "youtube_script" then "YouTube Script"
    else platform.titleize
    end
  end

  def status_color
    case status
    when "draft" then "gray"
    when "review" then "yellow"
    when "published" then "green"
    end
  end

  def word_count
    body&.split&.size || 0
  end
end
