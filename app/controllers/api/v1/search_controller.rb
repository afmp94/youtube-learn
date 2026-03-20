module Api
  module V1
    class SearchController < BaseController
      def index
        query = params[:q].to_s.strip
        return render json: { error: "Query parameter 'q' is required" }, status: :bad_request if query.blank?

        limit = [params.fetch(:limit, 10).to_i, 50].min
        filters = {
          tags: params[:tags],
          channel: params[:channel],
          difficulty: params[:difficulty]
        }.compact_blank

        results = Search::Hybrid.new(user: current_user, query: query, limit: limit, filters: filters).call

        render json: {
          query: query,
          count: results.size,
          results: results.map { |vl| serialize_video(vl) }
        }
      end

      private

      def serialize_video(vl)
        {
          id: vl.id, title: vl.title, channel_name: vl.channel_name,
          youtube_url: vl.youtube_url, summary: vl.summary,
          key_takeaways: vl.key_takeaways, concepts: vl.concepts,
          difficulty_level: vl.difficulty_level, tags: vl.tag_list,
          duration_seconds: vl.duration_seconds
        }
      end
    end
  end
end
