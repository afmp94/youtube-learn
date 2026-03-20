class ChannelsController < ApplicationController
  before_action :require_authentication
  before_action :set_channel, only: [:show, :edit, :update]

  def index
    @channels = Current.user.channels.by_video_count.includes(:video_learnings)
  end

  def show
    @video_learnings = @channel.video_learnings.recent.includes(:tags)
    @top_concepts = @channel.top_concepts(20)
    @key_takeaways = @channel.video_learnings.completed
                             .where.not(key_takeaways: nil)
                             .pluck(:key_takeaways)
                             .flatten
                             .first(20)
  end

  def edit
  end

  def update
    if @channel.update(channel_params)
      redirect_to @channel, notice: "Expert profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def sync_videos
    count = Channels::SyncService.new(Current.user).call
    if count > 0
      redirect_to channels_path, notice: "Synced #{count} new #{"expert".pluralize(count)}."
    else
      redirect_to channels_path, notice: "All experts are up to date."
    end
  end

  private

  def set_channel
    @channel = Current.user.channels.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(:description, :notes)
  end
end
