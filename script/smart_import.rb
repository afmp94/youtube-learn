#!/usr/bin/env ruby
# Smart cross-channel importer — Phase 1: Records + Transcripts
# Creates VideoLearning records and extracts transcripts via youtube-transcript-rb.
# NO yt-dlp needed (avoids YouTube bot detection).
# Claude analysis handled separately by Claude Code agents.
#
# Usage: bin/rails runner script/smart_import.rb
#
# ENV options:
#   DELAY_SECONDS=5    Delay between videos (default 5)
#   SKIP_DISCOVERY=1   Use cached video URLs only
#   START_AT=100       Resume from video #100 in the queue

CHANNELS = {
  "My First Million"       => "https://www.youtube.com/@MyFirstMillionPod/videos",
  "PBD Podcast"            => "https://www.youtube.com/@PBDPodcast/videos",
  "GaryVee"                => "https://www.youtube.com/@garyvee/videos",
  "Neil Patel"             => "https://www.youtube.com/@NeilPatel/videos",
  "Simon Squibb"           => "https://www.youtube.com/@SimonSquibb/videos",
  "Mark Tilbury"           => "https://www.youtube.com/@MarkTilbury/videos",
  "Daniel Priestley"       => "https://www.youtube.com/@DanielPriestley/videos",
  "The Anatomy of a Dream" => "https://www.youtube.com/@theanatomyofadream/videos",
  "Matt Gray"              => "https://www.youtube.com/@realmattgray/videos"
}.freeze

DELAY_SECONDS = ENV.fetch("DELAY_SECONDS", 5).to_i
START_AT = ENV.fetch("START_AT", 0).to_i
user = User.first

# ── Load cached video lists ──
puts "=" * 60
puts "Loading video lists from #{CHANNELS.size} channels"
puts "=" * 60

channel_videos = {}

CHANNELS.each do |name, url|
  cache_file = Rails.root.join("tmp", "import_cache_#{name.parameterize}.json")

  if File.exist?(cache_file)
    videos = JSON.parse(File.read(cache_file))
    puts "  #{name}: #{videos.size} videos (cached)"
    channel_videos[name] = videos
  else
    puts "  #{name}: NO CACHE — run discovery first"
  end
end

# ── Filter already-imported ──
existing_ids = user.video_learnings.pluck(:youtube_video_id).compact.to_set

channel_videos.each do |name, videos|
  before = videos.size
  videos.reject! { |v| existing_ids.include?(v["id"]) }
  puts "  #{name}: #{videos.size} new" if before != videos.size
end

total_new = channel_videos.values.sum(&:size)
puts "\nNew videos to process: #{total_new}"

if total_new == 0
  puts "Nothing to import!"
  exit
end

# ── Interleave round-robin (recent first per channel) ──
queues = channel_videos.select { |_, v| v.any? }.map { |name, videos|
  videos.map { |v| v.merge("channel_hint" => name) }
}

interleaved = []
max_len = queues.map(&:size).max || 0
max_len.times do |i|
  queues.each do |q|
    interleaved << q[i] if i < q.size
  end
end

# Support resuming
if START_AT > 0
  interleaved = interleaved[START_AT..]
  puts "Resuming from position #{START_AT}"
end

puts "Queue: #{interleaved.size} videos\n\n"

# ── Process: create records + extract transcripts ──
processed = 0
failed = 0
skipped = 0
no_transcript = 0
start_time = Time.current

interleaved.each_with_index do |video_info, index|
  video_id = video_info["id"]
  channel_hint = video_info["channel_hint"]
  video_url = "https://www.youtube.com/watch?v=#{video_id}"

  # Skip duplicates
  if user.video_learnings.exists?(youtube_video_id: video_id)
    skipped += 1
    next
  end

  print "[#{START_AT + index + 1}] [#{channel_hint}] #{video_info['title']&.truncate(50)}... "

  begin
    # Create the record
    vl = user.video_learnings.create!(
      youtube_url: video_url,
      youtube_video_id: video_id,
      title: video_info["title"],
      channel_name: channel_hint,
      status: :extracting
    )

    # Extract transcript via gem (no yt-dlp)
    begin
      transcript = YouTubeTranscript::Transcript.fetch(video_id)
      segments = transcript.map do |seg|
        { text: seg["text"], start: seg["start"], duration: seg["dur"] || seg["duration"] }
      end
      vl.update!(
        transcript_text: segments.map { |s| s[:text] }.join(" "),
        transcript_data: segments,
        processing_progress: 30
      )
      puts "ok (#{segments.size} segments)"
    rescue => e
      vl.update!(processing_progress: 10)
      no_transcript += 1
      puts "ok (no transcript: #{e.message.truncate(40)})"
    end

    # Auto-assign channel
    Channels::AutoAssign.new(vl).call rescue nil

    processed += 1

  rescue ActiveRecord::RecordInvalid
    skipped += 1
    puts "duplicate"
  rescue => e
    failed += 1
    puts "ERROR: #{e.message.truncate(60)}"
  end

  # Delay between videos
  sleep(DELAY_SECONDS + rand(3)) if index < interleaved.size - 1

  # Progress every 50
  if (index + 1) % 50 == 0
    elapsed = (Time.current - start_time).to_i
    rate = processed > 0 ? (processed.to_f / elapsed * 3600).round(0) : 0
    puts "\n--- #{processed} ok | #{failed} failed | #{no_transcript} no transcript | #{rate}/hr | #{(elapsed / 60.0).round(1)}min elapsed ---\n"
  end
end

elapsed = (Time.current - start_time).to_i
puts "\n#{'=' * 60}"
puts "IMPORT COMPLETE (#{(elapsed / 60.0).round(1)} minutes)"
puts "  Created with transcript: #{processed - no_transcript}"
puts "  Created without transcript: #{no_transcript}"
puts "  Failed:  #{failed}"
puts "  Skipped: #{skipped}"
puts ""
awaiting = user.video_learnings.where(status: :extracting).count
puts "Videos awaiting Claude analysis: #{awaiting}"
puts "=" * 60
