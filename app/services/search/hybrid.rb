module Search
  class Hybrid
    RRF_K = 60

    def initialize(user:, query:, limit: 10, filters: {})
      @user = user
      @query = query
      @limit = limit
      @filters = filters
    end

    def call
      query_embedding = Embeddings::Generator.new.generate(@query)

      semantic_ids = semantic_search(query_embedding)
      fulltext_ids = fulltext_search

      scores = {}
      semantic_ids.each_with_index do |id, rank|
        scores[id] ||= 0.0
        scores[id] += 1.0 / (RRF_K + rank + 1)
      end
      fulltext_ids.each_with_index do |id, rank|
        scores[id] ||= 0.0
        scores[id] += 1.0 / (RRF_K + rank + 1)
      end

      ranked_ids = scores.sort_by { |_, score| -score }.first(@limit).map(&:first)
      videos = VideoLearning.where(id: ranked_ids).index_by(&:id)
      ranked_ids.filter_map { |id| videos[id] }
    end

    private

    def base_scope
      scope = @user.video_learnings.completed
      scope = scope.joins(:tags).where(tags: { name: @filters[:tags] }) if @filters[:tags].present?
      scope = scope.where(channel_name: @filters[:channel]) if @filters[:channel].present?
      scope = scope.where(difficulty_level: @filters[:difficulty]) if @filters[:difficulty].present?
      scope
    end

    def semantic_search(query_embedding)
      base_scope.where.not(embedding: nil)
        .nearest_neighbors(:embedding, query_embedding, distance: "cosine")
        .limit(20)
        .pluck(:id)
    end

    def fulltext_search
      base_scope.search(@query).limit(20).pluck(:id)
    rescue PgSearch::EmptyQueryError
      []
    end
  end
end
