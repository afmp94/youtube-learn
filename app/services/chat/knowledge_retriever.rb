module Chat
  class KnowledgeRetriever
    MAX_CONTEXT_LENGTH = 30_000

    def initialize(user, query)
      @user = user
      @query = query
    end

    def call
      videos = find_relevant_videos
      context = compile_context(videos)

      { videos: videos, context: context }
    end

    private

    def find_relevant_videos
      results = search_with_pg_search

      if results.length < 3
        keyword_results = search_with_keywords
        results = (results + keyword_results).uniq.first(10)
      end

      results
    end

    def search_with_pg_search
      @user.video_learnings.completed.search(@query).limit(10).to_a
    rescue PgSearch::EmptyQueryError
      []
    end

    def search_with_keywords
      words = @query.downcase.split(/\s+/).reject { |w| w.length < 3 }
      return [] if words.empty?

      scope = @user.video_learnings.completed
      sql_parts = []
      bind_values = []

      words.each do |word|
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(word)}%"
        sql_parts << "(LOWER(title) LIKE ? OR LOWER(summary) LIKE ? OR LOWER(channel_name) LIKE ?)"
        bind_values.push(pattern, pattern, pattern)
      end

      scope.where(sql_parts.join(" OR "), *bind_values).limit(10).to_a
    end

    def compile_context(videos)
      return "" if videos.empty?

      context_parts = videos.map { |video| format_video_knowledge(video) }
      context = context_parts.join("\n\n---\n\n")

      truncate_context(context)
    end

    def format_video_knowledge(video)
      parts = []
      parts << "[From: #{video.title} by #{video.channel_name}] (Video ID: #{video.id})"

      if video.summary.present?
        parts << "Summary: #{video.summary}"
      end

      if video.key_takeaways.present? && video.key_takeaways.any?
        takeaways = video.key_takeaways.map { |t| "  - #{t}" }.join("\n")
        parts << "Key Takeaways:\n#{takeaways}"
      end

      if video.concepts.present? && video.concepts.any?
        concepts = video.concepts.map { |c|
          name = c["name"] || c[:name]
          desc = c["description"] || c[:description]
          "  - #{name}: #{desc}"
        }.join("\n")
        parts << "Concepts:\n#{concepts}"
      end

      if video.detailed_notes.present?
        parts << "Detailed Notes:\n#{video.detailed_notes.truncate(3000)}"
      end

      parts.join("\n\n")
    end

    def truncate_context(context)
      return context if context.length <= MAX_CONTEXT_LENGTH

      context[0...MAX_CONTEXT_LENGTH]
    end
  end
end
