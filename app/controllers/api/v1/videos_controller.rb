module Api
  module V1
    class VideosController < BaseController
      def index
        scope = current_user.video_learnings.recent
        scope = scope.by_status(params[:status]) if params[:status].present?
        scope = scope.joins(:tags).where(tags: { name: params[:tag] }) if params[:tag].present?
        scope = scope.where(channel_name: params[:channel]) if params[:channel].present?

        @pagy, videos = pagy(scope, limit: [params.fetch(:per_page, 20).to_i, 100].min)

        render json: {
          videos: videos.map { |vl| serialize_video(vl) },
          pagination: pagy_metadata(@pagy)
        }
      end

      def show
        vl = current_user.video_learnings.find(params[:id])
        render json: serialize_video_full(vl)
      end

      def stats
        completed = current_user.video_learnings.completed
        render json: {
          total_videos: current_user.video_learnings.count,
          completed: completed.count,
          total_duration_hours: (completed.sum(:duration_seconds).to_f / 3600).round(1),
          unique_channels: completed.distinct.count(:channel_name),
          difficulty_breakdown: completed.group(:difficulty_level).count,
          top_channels: completed.group(:channel_name).order(Arel.sql("COUNT(*) DESC")).limit(15).count,
          top_tags: Tag.joins(:video_learning_tags)
            .where(video_learning_tags: { video_learning_id: completed.select(:id) })
            .group(:name).order(Arel.sql("COUNT(*) DESC")).limit(20).count
        }
      end

      private

      def serialize_video(vl)
        {
          id: vl.id, title: vl.title, channel_name: vl.channel_name,
          youtube_url: vl.youtube_url, status: vl.status,
          summary: vl.summary&.truncate(300),
          difficulty_level: vl.difficulty_level,
          tags: vl.tag_list, duration_seconds: vl.duration_seconds,
          created_at: vl.created_at
        }
      end

      def serialize_video_full(vl)
        {
          id: vl.id, title: vl.title, channel_name: vl.channel_name,
          youtube_url: vl.youtube_url, youtube_video_id: vl.youtube_video_id,
          status: vl.status, summary: vl.summary,
          key_takeaways: vl.key_takeaways, concepts: vl.concepts,
          detailed_notes: vl.detailed_notes, difficulty_level: vl.difficulty_level,
          estimated_read_time: vl.estimated_read_time,
          tags: vl.tag_list, duration_seconds: vl.duration_seconds,
          published_at: vl.published_at, created_at: vl.created_at,
          transcript_text: vl.transcript_text&.truncate(10_000),
          quotes: vl.quotes.map { |q| { text: q.text, speaker: q.speaker, timestamp_seconds: q.timestamp_seconds } }
        }
      end
    end
  end
end
