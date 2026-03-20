module Api
  module V1
    class TagsController < BaseController
      def index
        tags = Tag.joins(:video_learning_tags)
          .joins("INNER JOIN video_learnings ON video_learnings.id = video_learning_tags.video_learning_id")
          .where(video_learnings: { user_id: current_user.id })
          .group("tags.id, tags.name")
          .order(Arel.sql("COUNT(*) DESC"))
          .select("tags.*, COUNT(*) as video_count")

        render json: {
          tags: tags.map { |t| { id: t.id, name: t.name, video_count: t.video_count } }
        }
      end

      def show
        tag = Tag.find(params[:id])
        videos = current_user.video_learnings.completed.joins(:tags).where(tags: { id: tag.id }).recent.limit(50)

        render json: {
          tag: { id: tag.id, name: tag.name },
          videos: videos.map { |vl| { id: vl.id, title: vl.title, channel_name: vl.channel_name, summary: vl.summary&.truncate(200) } }
        }
      end
    end
  end
end
