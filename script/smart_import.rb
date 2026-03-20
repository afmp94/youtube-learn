#!/usr/bin/env ruby
# Smart cross-channel importer
# Discovers videos from multiple channels, interleaves them (recent first),
# and processes one at a time with delays to avoid YouTube rate limiting.
#
# Usage: bin/rails runner script/smart_import.rb
#
# Set DELAY_SECONDS env var to control delay between videos (default: 15)
# Set SKIP_DISCOVERY=1 to skip yt-dlp discovery and use cached video_urls from DB

CHANNELS = {
  "My First Million"       => "https://www.youtube.com/@MyFirstMillion/videos",
  "PBD Podcast"            => "https://www.youtube.com/@PBDPodcast/videos",
  "GaryVee"                => "https://www.youtube.com/@garyvee/videos",
  "Neil Patel"             => "https://www.youtube.com/@NeilPatel/videos",
  "Simon Squibb"           => "https://www.youtube.com/@SimonSquibb/videos",
  "Mark Tilbury"           => "https://www.youtube.com/@MarkTilbury/videos",
  "Daniel Priestley"       => "https://www.youtube.com/@DanielPriestley/videos",
  "The Anatomy of a Dream" => "https://www.youtube.com/@theanatomyofadream/videos",
  "Matt Gray"              => "https://www.youtube.com/@realmattgray/videos"
}.freeze

DELAY_SECONDS = ENV.fetch("DELAY_SECONDS", 15).to_i
user = User.first

# ── Phase 1: Discover all video URLs from each channel ──
puts "=" * 60
puts "PHASE 1: Discovering videos from #{CHANNELS.size} channels"
puts "=" * 60

channel_videos = {}

CHANNELS.each do |name, url|
  puts "\n📡 #{name}: #{url}"

  cache_file = Rails.root.join("tmp", "import_cache_#{name.parameterize}.json")

  if ENV["SKIP_DISCOVERY"] == "1" && File.exist?(cache_file)
    videos = JSON.parse(File.read(cache_file))
    puts "   Using cached #{videos.size} videos"
  else
    begin
      videos = Imports::PlaylistExtractor.new(url).call
      # Cache the results
      File.write(cache_file, videos.to_json)
      puts "   Found #{videos.size} videos (cached to #{cache_file.basename})"
    rescue => e
      puts "   ❌ Failed: #{e.message}"
      next
    end
  end

  # yt-dlp returns most recent first by default, which is what we want
  channel_videos[name] = videos
end

total_discovered = channel_videos.values.sum(&:size)
puts "\n\nTotal discovered: #{total_discovered} videos across #{channel_videos.size} channels"

# ── Phase 2: Filter out already-imported videos ──
existing_ids = user.video_learnings.pluck(:youtube_video_id).to_set
puts "Already imported: #{existing_ids.size} videos"

channel_videos.each do |name, videos|
  before = videos.size
  videos.reject! { |v| existing_ids.include?(v["id"]) }
  skipped = before - videos.size
  puts "  #{name}: #{videos.size} new (#{skipped} already imported)"
end

total_new = channel_videos.values.sum(&:size)
puts "\nNew videos to import: #{total_new}"

if total_new == 0
  puts "Nothing to import!"
  exit
end

# ── Phase 3: Interleave round-robin (recent first per channel) ──
# Each channel's list is already sorted recent-first from yt-dlp.
# We round-robin across channels so we don't hammer one channel repeatedly.
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

puts "\nInterleaved queue: #{interleaved.size} videos"
puts "Order preview (first 20):"
interleaved.first(20).each_with_index do |v, i|
  puts "  #{(i + 1).to_s.rjust(3)}. [#{v['channel_hint']}] #{v['title']&.truncate(60)}"
end

# ── Phase 4: Process one at a time ──
puts "\n#{'=' * 60}"
puts "PHASE 4: Processing #{interleaved.size} videos (1 at a time, #{DELAY_SECONDS}s delay)"
puts "=" * 60

processed = 0
failed = 0
skipped = 0

interleaved.each_with_index do |video_info, index|
  video_id = video_info["id"]
  video_url = video_info["url"]
  video_url = "https://www.youtube.com/watch?v=#{video_id}" if video_url.blank? || !video_url.start_with?("http")
  channel_hint = video_info["channel_hint"]

  # Double-check for duplicates (in case another process imported it)
  if user.video_learnings.exists?(youtube_video_id: video_id)
    skipped += 1
    next
  end

  print "[#{index + 1}/#{interleaved.size}] [#{channel_hint}] #{video_info['title']&.truncate(50)}... "

  begin
    vl = user.video_learnings.create!(
      youtube_url: video_url,
      youtube_video_id: video_id,
      title: video_info["title"]
    )

    # Process synchronously (not via job queue) — one at a time
    begin
      Videos::MetadataExtractor.new(vl).call
      Videos::TranscriptExtractor.new(vl).call
      # Skip frame extraction — transcript-only for bulk import
      Videos::ClaudeAnalyzer.new(vl).call

      if vl.concepts.present?
        suggested = vl.concepts.map { |c| c["name"] }.compact.first(5)
        vl.tag_list = suggested if suggested.any?
      end

      Channels::AutoAssign.new(vl).call rescue nil

      vl.update!(status: :completed, processing_progress: 100)

      # Generate embedding inline
      begin
        text = Embeddings::VideoLearningEmbedder.new(vl).embeddable_text
        embedding = Embeddings::Generator.new.generate(text)
        vl.update_columns(embedding: embedding, embedding_generated_at: Time.current)
      rescue => e
        puts "(embedding failed: #{e.message})"
      end

      processed += 1
      puts "✅"

    rescue Videos::VideoUnavailableError => e
      vl.update!(status: :failed, error_message: e.message)
      failed += 1
      puts "⏭️  unavailable"
    rescue Videos::Error => e
      vl.update!(status: :failed, error_message: e.message)
      failed += 1
      puts "❌ #{e.message.truncate(60)}"
    rescue => e
      vl.update!(status: :failed, error_message: "Unexpected: #{e.message}")
      failed += 1
      puts "❌ #{e.message.truncate(60)}"
    end

  rescue ActiveRecord::RecordInvalid => e
    skipped += 1
    puts "⏭️  duplicate"
  end

  # Delay between videos to avoid YouTube rate limiting
  if index < interleaved.size - 1
    sleep(DELAY_SECONDS + rand(5))
  end

  # Progress report every 50 videos
  if (index + 1) % 50 == 0
    elapsed = Time.current
    puts "\n--- Progress: #{processed} processed, #{failed} failed, #{skipped} skipped (#{index + 1}/#{interleaved.size}) ---\n"
  end
end

puts "\n#{'=' * 60}"
puts "COMPLETE!"
puts "  Processed: #{processed}"
puts "  Failed:    #{failed}"
puts "  Skipped:   #{skipped}"
puts "  Total:     #{interleaved.size}"
puts "=" * 60
