module Api
  module V1
    class QuotesController < BaseController
      def index
        scope = user_quotes.includes(:video_learning)
        scope = scope.where(speaker: params[:speaker]) if params[:speaker].present?
        @pagy, quotes = pagy(scope.order(created_at: :desc), limit: [params.fetch(:per_page, 20).to_i, 100].min)

        render json: {
          quotes: quotes.map { |q| serialize_quote(q) },
          pagination: pagy_metadata(@pagy)
        }
      end

      def search
        query = params[:q].to_s.strip
        return render json: { error: "Query required" }, status: :bad_request if query.blank?

        quotes = user_quotes.includes(:video_learning)
          .where("quotes.text ILIKE ?", "%#{query}%")
          .limit(20)

        render json: { quotes: quotes.map { |q| serialize_quote(q) } }
      end

      private

      def user_quotes
        Quote.joins(:video_learning).where(video_learnings: { user_id: current_user.id })
      end

      def serialize_quote(q)
        {
          id: q.id, text: q.text, speaker: q.speaker,
          timestamp_seconds: q.timestamp_seconds,
          video: { id: q.video_learning_id, title: q.video_learning.title, channel: q.video_learning.channel_name }
        }
      end
    end
  end
end
