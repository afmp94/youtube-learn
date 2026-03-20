module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend

      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        token = request.headers["Authorization"]&.match(/^Bearer\s+(.+)$/)&.captures&.first
        @api_key = ApiKey.authenticate(token)

        unless @api_key
          render json: { error: "Invalid or expired API key" }, status: :unauthorized
        end
      end

      def current_user
        @api_key&.user
      end

      def pagy_metadata(pagy)
        { current_page: pagy.page, total_pages: pagy.pages, total_count: pagy.count, per_page: pagy.limit }
      end
    end
  end
end
