module Channels
  class AutoAssign
    def initialize(video_learning)
      @video_learning = video_learning
    end

    def call
      return unless @video_learning.channel_name.present?
      return if @video_learning.channel_id.present?

      user = @video_learning.user

      channel = user.channels.find_or_create_by!(name: @video_learning.channel_name) do |ch|
        ch.thumbnail_url = @video_learning.thumbnail_url
      end

      @video_learning.update_column(:channel_id, channel.id)
      channel
    end
  end
end
