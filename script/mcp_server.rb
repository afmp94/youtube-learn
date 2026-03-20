#!/usr/bin/env ruby
# MCP Server for YouTube Learn knowledge base
# Usage: ruby script/mcp_server.rb
#
# Claude Desktop config (~/.claude/claude_desktop_config.json):
# {
#   "mcpServers": {
#     "youtube-learn": {
#       "command": "docker",
#       "args": ["compose", "exec", "-T", "web", "ruby", "script/mcp_server.rb"],
#       "cwd": "/path/to/youtube_learn"
#     }
#   }
# }

require_relative "../config/environment"
require "fast_mcp"

# Helper to get the default user (single-user mode for MCP)
def default_user
  @default_user ||= User.first
end

# --- Tool definitions ---

class SearchVideos < FastMcp::Tool
  tool_name "search_videos"
  description "Semantic + fulltext hybrid search across 4700+ analyzed YouTube videos from top business/tech creators"

  arguments do
    required(:query).filled(:string).description("Search query - semantic meaning is matched, not just keywords")
    optional(:limit).filled(:integer).description("Max results to return (default 10)")
    optional(:tags).array(:string).description("Filter by tags, e.g. ['entrepreneurship', 'sales']")
    optional(:channel).filled(:string).description("Filter by channel name")
    optional(:difficulty).filled(:string).description("Filter by difficulty: beginner, intermediate, advanced")
  end

  def call(query:, limit: 10, tags: nil, channel: nil, difficulty: nil)
    user = User.first
    results = Search::Hybrid.new(
      user: user, query: query, limit: limit,
      filters: { tags: tags, channel: channel, difficulty: difficulty }.compact
    ).call

    results.map do |vl|
      { id: vl.id, title: vl.title, channel: vl.channel_name, summary: vl.summary,
        key_takeaways: vl.key_takeaways, youtube_url: "https://youtube.com/watch?v=#{vl.youtube_video_id}" }
    end.to_json
  end
end

class GetVideo < FastMcp::Tool
  tool_name "get_video"
  description "Get full details of a specific video learning including notes, concepts, and quotes"

  arguments do
    required(:id).filled(:integer).description("Video learning ID")
  end

  def call(id:)
    vl = VideoLearning.find(id)
    { id: vl.id, title: vl.title, channel: vl.channel_name, summary: vl.summary,
      key_takeaways: vl.key_takeaways, concepts: vl.concepts, detailed_notes: vl.detailed_notes,
      difficulty_level: vl.difficulty_level,
      quotes: vl.quotes.map { |q| { text: q.text, speaker: q.speaker, timestamp: q.timestamp_seconds } },
      youtube_url: "https://youtube.com/watch?v=#{vl.youtube_video_id}" }.to_json
  end
end

class ListChannels < FastMcp::Tool
  tool_name "list_channels"
  description "List all analyzed YouTube channels with video counts and expertise areas"

  arguments do
  end

  def call
    Channel.joins(:video_learnings)
      .group("channels.id")
      .select("channels.*, COUNT(video_learnings.id) as video_count")
      .order("video_count DESC")
      .map { |c| { id: c.id, name: c.name, video_count: c.video_count, expertise: c.expertise_areas } }
      .to_json
  end
end

class GetChannelInsights < FastMcp::Tool
  tool_name "get_channel_insights"
  description "Get a channel's profile, expertise areas, and recent video learnings"

  arguments do
    required(:id).filled(:integer).description("Channel ID")
    optional(:limit).filled(:integer).description("Max videos to return (default 20)")
  end

  def call(id:, limit: 20)
    channel = Channel.find(id)
    videos = channel.video_learnings.completed.order(created_at: :desc).limit(limit)
    { channel: { id: channel.id, name: channel.name, expertise: channel.expertise_areas, bio: channel.bio },
      videos: videos.map { |vl| { id: vl.id, title: vl.title, summary: vl.summary&.truncate(200) } } }.to_json
  end
end

class FindQuotes < FastMcp::Tool
  tool_name "find_quotes"
  description "Search for notable quotes across all analyzed videos"

  arguments do
    optional(:query).filled(:string).description("Text search within quotes")
    optional(:speaker).filled(:string).description("Filter by speaker name")
    optional(:limit).filled(:integer).description("Max results (default 20)")
  end

  def call(query: nil, speaker: nil, limit: 20)
    user = User.first
    quotes = Quote.joins(:video_learning)
      .where(video_learnings: { user_id: user.id })
      .includes(:video_learning)
    quotes = quotes.where("quotes.text ILIKE ?", "%#{query}%") if query.present?
    quotes = quotes.where(speaker: speaker) if speaker.present?

    quotes.limit(limit).map do |q|
      { text: q.text, speaker: q.speaker, timestamp: q.timestamp_seconds,
        video: q.video_learning.title, channel: q.video_learning.channel_name }
    end.to_json
  end
end

class GetConcepts < FastMcp::Tool
  tool_name "get_concepts"
  description "Get key concepts and their frequency across all analyzed videos"

  arguments do
    optional(:min_count).filled(:integer).description("Minimum occurrence count (default 2)")
    optional(:limit).filled(:integer).description("Max results (default 50)")
  end

  def call(min_count: 2, limit: 50)
    user = User.first
    videos = user.video_learnings.completed.where.not(concepts: nil)
    all_concepts = videos.pluck(:concepts).flatten.compact

    grouped = all_concepts.group_by { |c| c["name"]&.downcase&.strip }

    results = grouped.filter_map do |name, occurrences|
      next if name.blank? || occurrences.size < min_count
      { name: occurrences.first["name"], count: occurrences.size,
        descriptions: occurrences.map { |c| c["description"] }.uniq.compact.first(3) }
    end

    results.sort_by { |c| -c[:count] }.first(limit).to_json
  end
end

class KnowledgeStats < FastMcp::Tool
  tool_name "knowledge_stats"
  description "Get overall statistics about the YouTube Learn knowledge base"

  arguments do
  end

  def call
    user = User.first
    videos = user.video_learnings
    { total_videos: videos.count, completed: videos.completed.count,
      channels: videos.distinct.count(:channel_name),
      tags: Tag.joins(:video_learning_tags)
        .joins("INNER JOIN video_learnings ON video_learnings.id = video_learning_tags.video_learning_id")
        .where(video_learnings: { user_id: user.id }).distinct.count,
      quotes: Quote.joins(:video_learning).where(video_learnings: { user_id: user.id }).count,
      with_embeddings: videos.where.not(embedding: nil).count }.to_json
  end
end

class FindRelatedVideos < FastMcp::Tool
  tool_name "find_related_videos"
  description "Find semantically similar videos to a given video using vector embeddings"

  arguments do
    required(:id).filled(:integer).description("Video learning ID to find related videos for")
    optional(:limit).filled(:integer).description("Max results (default 5)")
  end

  def call(id:, limit: 5)
    vl = VideoLearning.find(id)
    return { error: "Video has no embedding yet" }.to_json unless vl.embedding.present?

    related = vl.nearest_neighbors(:embedding, distance: "cosine").first(limit)
    related.map do |r|
      { id: r.id, title: r.title, channel: r.channel_name,
        summary: r.summary&.truncate(200), similarity: (1 - r.neighbor_distance).round(3) }
    end.to_json
  end
end

# --- Server setup ---

server = FastMcp::Server.new(name: "youtube-learn", version: "1.0.0")

server.register_tools(
  SearchVideos,
  GetVideo,
  ListChannels,
  GetChannelInsights,
  FindQuotes,
  GetConcepts,
  KnowledgeStats,
  FindRelatedVideos
)

server.start
