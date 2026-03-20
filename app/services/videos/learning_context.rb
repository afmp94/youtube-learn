module Videos
  class LearningContext
    MAX_CONTEXT_TOKENS = 10_000

    def initialize(user)
      @user = user
    end

    def call
      recent_learnings = @user.video_learnings
        .completed
        .order(created_at: :desc)
        .limit(20)

      return "" if recent_learnings.empty?

      sections = recent_learnings.map do |vl|
        parts = ["Topic: #{vl.title}"]
        if vl.key_takeaways.present?
          parts << "Key Takeaways: #{vl.key_takeaways.join('; ')}"
        end
        if vl.concepts.present?
          concept_names = vl.concepts.map { |c| c["name"] }.compact
          parts << "Concepts: #{concept_names.join(', ')}" if concept_names.any?
        end
        parts.join("\n")
      end

      sections.join("\n---\n").truncate(MAX_CONTEXT_TOKENS * 4)
    end
  end
end
