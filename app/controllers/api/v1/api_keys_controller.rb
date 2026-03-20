module Api
  module V1
    class ApiKeysController < BaseController
      def index
        keys = current_user.api_keys.order(created_at: :desc)
        render json: {
          api_keys: keys.map { |k|
            { id: k.id, name: k.name, prefix: k.token_prefix,
              last_used_at: k.last_used_at, active: k.active?, created_at: k.created_at }
          }
        }
      end

      def create
        raw_token = ApiKey.generate_token
        key = current_user.api_keys.create!(
          name: params[:name] || "API Key",
          token_digest: Digest::SHA256.hexdigest(raw_token),
          token_prefix: raw_token[0..7]
        )

        render json: {
          api_key: { id: key.id, name: key.name, token: raw_token, prefix: key.token_prefix },
          warning: "Store this token securely. It will not be shown again."
        }, status: :created
      end

      def destroy
        key = current_user.api_keys.find(params[:id])
        key.revoke!
        render json: { message: "API key revoked" }
      end
    end
  end
end
