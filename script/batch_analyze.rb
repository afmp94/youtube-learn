#!/usr/bin/env ruby
# Batch analyze videos that have transcripts but no Claude analysis.
# Runs the existing ClaudeAnalyzer service + generates embeddings.
#
# Usage: bin/rails runner script/batch_analyze.rb
#
# ENV options:
#   BATCH_SIZE=20     Number of videos to analyze (default 20)
#   DELAY=2           Seconds between API calls (default 2)
#   OFFSET=0          Skip first N eligible videos (default 0)

BATCH_SIZE = ENV.fetch("BATCH_SIZE", 20).to_i
DELAY = ENV.fetch("DELAY", 2).to_i
OFFSET = ENV.fetch("OFFSET", 0).to_i

user = User.first

# Find videos with transcripts but no analysis
candidates = user.video_learnings
  .where(status: :extracting)
  .where.not(transcript_text: [nil, ""])
  .where(summary: nil)
  .order(:id)

total_eligible = candidates.count
batch = candidates.offset(OFFSET).limit(BATCH_SIZE)

puts "=" * 60
puts "BATCH ANALYZE"
puts "  Eligible: #{total_eligible}"
puts "  Batch: #{batch.count} (offset=#{OFFSET}, limit=#{BATCH_SIZE})"
puts "  Delay: #{DELAY}s between calls"
puts "=" * 60
puts ""

analyzed = 0
failed = 0
start_time = Time.current

batch.each_with_index do |vl, i|
  print "[#{i + 1}/#{batch.count}] #{vl.channel_name}: #{vl.title.to_s.truncate(50)}... "

  begin
    # Run Claude analysis (uses existing service)
    Videos::ClaudeAnalyzer.new(vl).call

    # Mark as completed
    vl.update!(status: :completed, processing_progress: 100)

    # Generate embedding
    begin
      Embeddings::VideoLearningEmbedder.new(vl).call
    rescue => e
      # Non-fatal — embedding can be retried later
      $stderr.puts "  (embedding failed: #{e.message.truncate(40)})"
    end

    analyzed += 1
    puts "ok"

  rescue => e
    failed += 1
    puts "ERROR: #{e.message.truncate(80)}"
  end

  sleep(DELAY) if i < batch.count - 1
end

elapsed = (Time.current - start_time).to_i
puts ""
puts "=" * 60
puts "DONE (#{(elapsed / 60.0).round(1)} minutes)"
puts "  Analyzed: #{analyzed}"
puts "  Failed:   #{failed}"
puts "  Remaining: #{total_eligible - OFFSET - analyzed - failed}"
puts "=" * 60
