class ViralityAnalysis < ApplicationRecord
  belongs_to :user
  belongs_to :analyzable, polymorphic: true, optional: true

  enum :input_type, { free_text: 0, content_piece: 1, video_learning: 2, strategy: 3 }
  enum :status, { pending: 0, analyzing: 1, completed: 2, failed: 3 }
  enum :brain_status, {
    brain_pending: 0, brain_analyzing: 1, brain_completed: 2,
    brain_failed: 3, brain_skipped: 4
  }, prefix: :brain

  has_many_attached :brain_images

  validates :input_text, presence: true
  validates :input_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: :completed) }

  DIMENSIONS = %w[
    hook_power emotional_resonance shareability practical_value
    storytelling novelty platform_fit controversy
  ].freeze

  DIMENSION_LABELS = {
    "hook_power" => "Hook Power",
    "emotional_resonance" => "Emotional Resonance",
    "shareability" => "Shareability",
    "practical_value" => "Practical Value",
    "storytelling" => "Storytelling",
    "novelty" => "Novelty",
    "platform_fit" => "Platform Fit",
    "controversy" => "Controversy"
  }.freeze

  DIMENSION_ICONS = {
    "hook_power" => "M13 10V3L4 14h7v7l9-11h-7z",
    "emotional_resonance" => "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z",
    "shareability" => "M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z",
    "practical_value" => "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
    "storytelling" => "M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253",
    "novelty" => "M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z",
    "platform_fit" => "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z",
    "controversy" => "M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"
  }.freeze

  DIMENSION_COLORS = {
    "hook_power" => { bg: "bg-orange-500/20", text: "text-orange-400", bar: "bg-orange-500" },
    "emotional_resonance" => { bg: "bg-red-500/20", text: "text-red-400", bar: "bg-red-500" },
    "shareability" => { bg: "bg-blue-500/20", text: "text-blue-400", bar: "bg-blue-500" },
    "practical_value" => { bg: "bg-emerald-500/20", text: "text-emerald-400", bar: "bg-emerald-500" },
    "storytelling" => { bg: "bg-violet-500/20", text: "text-violet-400", bar: "bg-violet-500" },
    "novelty" => { bg: "bg-amber-500/20", text: "text-amber-400", bar: "bg-amber-500" },
    "platform_fit" => { bg: "bg-cyan-500/20", text: "text-cyan-400", bar: "bg-cyan-500" },
    "controversy" => { bg: "bg-pink-500/20", text: "text-pink-400", bar: "bg-pink-500" }
  }.freeze

  DIMENSION_HEX_COLORS = {
    "hook_power" => "#f97316",
    "emotional_resonance" => "#ef4444",
    "shareability" => "#3b82f6",
    "practical_value" => "#10b981",
    "storytelling" => "#8b5cf6",
    "novelty" => "#f59e0b",
    "platform_fit" => "#06b6d4",
    "controversy" => "#ec4899"
  }.freeze

  def score_color
    return "text-gray-400" unless overall_score
    if overall_score >= 70
      "text-emerald-400"
    elsif overall_score >= 40
      "text-yellow-400"
    else
      "text-red-400"
    end
  end

  def score_bg_color
    return "bg-gray-500/20" unless overall_score
    if overall_score >= 70
      "bg-emerald-500/20"
    elsif overall_score >= 40
      "bg-yellow-500/20"
    else
      "bg-red-500/20"
    end
  end

  def input_type_label
    case input_type
    when "free_text" then "Free Text"
    when "content_piece" then "Content"
    when "video_learning" then "Video"
    when "strategy" then "Strategy"
    end
  end

  def input_type_icon
    case input_type
    when "free_text" then "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
    when "content_piece" then "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
    when "video_learning" then "M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"
    when "strategy" then "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
    end
  end

  def excerpt
    input_text&.truncate(80)
  end

  # Brain region clusters mapped to content insights
  BRAIN_REGION_CLUSTERS = {
    "visual_processing" => {
      label: "Visual Impact",
      icon: "M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z",
      color: "#f97316",
      dimension: "hook_power"
    },
    "language_network" => {
      label: "Language Processing",
      icon: "M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z",
      color: "#8b5cf6",
      dimension: "storytelling"
    },
    "emotion_circuit" => {
      label: "Emotional Response",
      icon: "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z",
      color: "#ef4444",
      dimension: "emotional_resonance"
    },
    "reward_novelty" => {
      label: "Novelty & Reward",
      icon: "M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z",
      color: "#f59e0b",
      dimension: "novelty"
    },
    "social_cognition" => {
      label: "Social Cognition",
      icon: "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z",
      color: "#3b82f6",
      dimension: "shareability"
    },
    "auditory_processing" => {
      label: "Auditory Engagement",
      icon: "M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z",
      color: "#06b6d4",
      dimension: "practical_value"
    }
  }.freeze

  def brain_region_clusters
    brain_data&.dig("region_clusters") || {}
  end

  def brain_dimension_correlations
    brain_data&.dig("virality_correlations") || {}
  end

  def brain_top_regions
    brain_data&.dig("top_regions") || []
  end

  def brain_temporal_summary
    brain_data&.dig("temporal_summary") || {}
  end

  def brain_available?
    brain_brain_completed?
  end
end
