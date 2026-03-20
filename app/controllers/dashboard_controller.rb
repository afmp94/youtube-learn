class DashboardController < ApplicationController
  def show
    @recent_videos = Current.user.video_learnings.recent.limit(6)
    @total_count = Current.user.video_learnings.count
    @completed_count = Current.user.video_learnings.completed.count
    @content_count = Current.user.content_pieces.count
    @draft_count = Current.user.content_pieces.draft.count
    @published_count = Current.user.content_pieces.published.count
    @collection_count = Current.user.collections.count
    @channel_count = Current.user.channels.count
    @conversation_count = Current.user.conversations.count
    @quote_count = Quote.joins(:video_learning)
      .where(video_learnings: { user_id: Current.user.id }).count
    @tags = Current.user.video_learnings
      .joins(:tags)
      .select("tags.name, COUNT(*) as count")
      .group("tags.name")
      .order("count DESC")
      .limit(10)
    @recent_content = Current.user.content_pieces.recent.limit(4)
    @recent_quotes = Quote.joins(:video_learning)
      .where(video_learnings: { user_id: Current.user.id })
      .includes(video_learning: :channel)
      .recent.limit(3)
    @project_count = Current.user.projects.active.count
    @recent_projects = Current.user.projects.active.recent.limit(3)
    @top_channels = Current.user.channels.by_video_count.limit(5)
    @total_hours = (Current.user.video_learnings.completed
      .where.not(duration_seconds: nil)
      .sum(:duration_seconds) / 3600.0).round(1)
  end
end
