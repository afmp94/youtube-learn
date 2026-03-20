module Api
  module V1
    class ChannelsController < BaseController
      def index
        channels = current_user.channels.order(Arel.sql("(SELECT COUNT(*) FROM video_learnings WHERE video_learnings.channel_id = channels.id) DESC"))
        render json: {
          channels: channels.map { |ch| serialize_channel(ch) }
        }
      end

      def show
        channel = current_user.channels.find(params[:id])
        videos = channel.video_learnings.completed.recent.limit(50)
        render json: {
          channel: serialize_channel(channel),
          videos: videos.map { |vl| { id: vl.id, title: vl.title, summary: vl.summary&.truncate(200) } }
        }
      end

      private

      def serialize_channel(ch)
        {
          id: ch.id, name: ch.name, description: ch.description,
          video_count: ch.video_learnings.count,
          completed_count: ch.video_learnings.completed.count
        }
      end
    end
  end
end
