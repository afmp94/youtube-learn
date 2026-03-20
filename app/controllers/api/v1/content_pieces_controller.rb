module Api
  module V1
    class ContentPiecesController < BaseController
      def index
        scope = current_user.content_pieces.order(created_at: :desc)
        scope = scope.where(platform: params[:platform]) if params[:platform].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        @pagy, pieces = pagy(scope, limit: [params.fetch(:per_page, 20).to_i, 100].min)

        render json: {
          content_pieces: pieces.map { |cp| serialize_piece(cp) },
          pagination: pagy_metadata(@pagy)
        }
      end

      def show
        piece = current_user.content_pieces.find(params[:id])
        render json: serialize_piece(piece).merge(body: piece.body)
      end

      def create
        video_ids = Array(params[:video_ids]).map(&:to_i)
        videos = current_user.video_learnings.where(id: video_ids)

        return render json: { error: "No valid video IDs provided" }, status: :bad_request if videos.empty?

        piece = current_user.content_pieces.create!(
          platform: params[:platform] || "linkedin",
          content_format: params[:format] || "post",
          status: :draft,
          title: params[:title] || "Generated content",
          generation_prompt: params[:prompt]
        )

        videos.each { |v| piece.content_piece_sources.create!(video_learning: v) }
        GenerateContentJob.perform_later(piece.id)

        render json: serialize_piece(piece), status: :created
      end

      private

      def serialize_piece(cp)
        {
          id: cp.id, title: cp.title, platform: cp.platform,
          content_format: cp.content_format, status: cp.status,
          created_at: cp.created_at
        }
      end
    end
  end
end
