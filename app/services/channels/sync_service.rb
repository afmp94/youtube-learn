module Channels
  class SyncService
    def initialize(user)
      @user = user
    end

    def call
      new_channels_count = 0

      video_learnings_by_channel.each do |channel_name, video_learnings|
        channel = @user.channels.find_or_initialize_by(
          name: channel_name
        )

        if channel.new_record?
          # Pull thumbnail from the first video that has one
          sample = video_learnings.find { |vl| vl.thumbnail_url.present? }
          channel.thumbnail_url = sample&.thumbnail_url
          channel.save!
          new_channels_count += 1
        end

        # Assign channel_id to any unassigned video learnings
        unassigned = video_learnings.select { |vl| vl.channel_id.nil? }
        VideoLearning.where(id: unassigned.map(&:id)).update_all(channel_id: channel.id) if unassigned.any?
      end

      new_channels_count
    end

    private

    def video_learnings_by_channel
      @user.video_learnings
           .where.not(channel_name: [nil, ""])
           .group_by { |vl| normalize_name(vl.channel_name) }
           .transform_keys { |normalized| original_name_for(normalized) }
    end

    def normalize_name(name)
      name.strip.downcase
    end

    # Use the most common casing of the channel name across all videos
    def original_name_for(normalized)
      @user.video_learnings
           .where.not(channel_name: [nil, ""])
           .pluck(:channel_name)
           .select { |n| normalize_name(n) == normalized }
           .tally
           .max_by { |_, count| count }
           &.first || normalized
    end
  end
end
