class VideoLearning < ApplicationRecord
  include PgSearch::Model
  has_neighbors :embedding, dimensions: 768

  belongs_to :user
  belongs_to :channel, optional: true
  belongs_to :bulk_import, optional: true
  has_many :frames, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :video_learning_tags, dependent: :destroy
  has_many :tags, through: :video_learning_tags
  has_many :collection_video_learnings, dependent: :destroy
  has_many :collections, through: :collection_video_learnings
  has_many :content_piece_sources, dependent: :destroy
  has_many :content_pieces, through: :content_piece_sources
  has_many :project_video_learnings, dependent: :destroy
  has_many :projects, through: :project_video_learnings

  enum :status, { pending: 0, extracting: 1, analyzing: 2, completed: 3, failed: 4 }

  validates :youtube_url, presence: true
  validates :youtube_video_id, uniqueness: { scope: :user_id }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  pg_search_scope :search,
    against: { title: "A", summary: "B", detailed_notes: "C", transcript_text: "D" },
    using: { tsearch: { prefix: true, dictionary: "english" } }

  before_validation :extract_video_id, on: :create

  def youtube_embed_url
    "https://www.youtube.com/embed/#{youtube_video_id}" if youtube_video_id.present?
  end

  def formatted_duration
    return nil unless duration_seconds
    minutes = duration_seconds / 60
    seconds = duration_seconds % 60
    format("%d:%02d", minutes, seconds)
  end

  def tag_list
    tags.pluck(:name)
  end

  def tag_list=(names)
    self.tags = names.map(&:strip).reject(&:blank?).uniq.map do |name|
      Tag.find_or_create_by!(name: name.downcase)
    end
  end

  private

  def extract_video_id
    return if youtube_url.blank?
    uri = URI.parse(youtube_url) rescue nil
    return unless uri

    self.youtube_video_id = if uri.host&.include?("youtu.be")
      uri.path[1..]
    elsif uri.host&.include?("youtube.com")
      params = URI.decode_www_form(uri.query || "").to_h
      params["v"]
    end
  end
end
