#!/bin/bash
# Smart cross-channel importer — runs LOCALLY with Safari cookies
# Extracts metadata + transcripts via yt-dlp, writes to DB via Rails runner
#
# Usage: ./script/local_import.sh
# Resume: START_AT=500 ./script/local_import.sh

DELAY=${DELAY:-5}
START_AT=${START_AT:-0}
YTDLP="yt-dlp --cookies-from-browser safari --remote-components ejs:github"

PROCESSED=0
FAILED=0
SKIPPED=0

echo "=========================================="
echo "Building interleaved video queue..."
echo "=========================================="

docker compose exec -T web bin/rails runner tmp/build_queue.rb 2>/dev/null

QUEUE_FILE="tmp/import_queue.tsv"
TOTAL=$(wc -l < "$QUEUE_FILE" | tr -d ' ')
echo "Total: $TOTAL videos | Starting at: $START_AT | Delay: ${DELAY}s"
echo ""

LINE_NUM=0
while IFS=$'\t' read -r VIDEO_ID CHANNEL TITLE <&3; do
  LINE_NUM=$((LINE_NUM + 1))
  [ "$LINE_NUM" -le "$START_AT" ] && continue

  SHORT=$(echo "$TITLE" | cut -c1-50)
  printf "[%d/%d] [%s] %s... " "$LINE_NUM" "$TOTAL" "$CHANNEL" "$SHORT"

  # 1. Metadata
  META_FILE="/tmp/yt_meta_${VIDEO_ID}.json"
  $YTDLP --dump-json --no-download "https://www.youtube.com/watch?v=${VIDEO_ID}" > "$META_FILE" 2>/dev/null

  if [ ! -s "$META_FILE" ]; then
    echo "metadata failed"
    FAILED=$((FAILED + 1))
    rm -f "$META_FILE"
    sleep $((DELAY + RANDOM % 3))
    continue
  fi

  # 2. Transcript
  TRANS_DIR=$(mktemp -d)
  $YTDLP --skip-download --write-auto-sub --sub-lang en --sub-format json3 \
    -o "${TRANS_DIR}/subs" "https://www.youtube.com/watch?v=${VIDEO_ID}" 2>/dev/null

  TRANS_FILE="/tmp/yt_trans_${VIDEO_ID}.txt"
  if [ -f "${TRANS_DIR}/subs.en.json3" ]; then
    python3 -c "
import json
with open('${TRANS_DIR}/subs.en.json3') as f:
    data = json.load(f)
texts = []
for e in data.get('events',[]):
    for s in e.get('segs',[]):
        t = s.get('utf8','').strip()
        if t and t != '\n':
            texts.append(t)
with open('${TRANS_FILE}', 'w') as f:
    f.write(' '.join(texts))
" 2>/dev/null
  fi
  [ ! -f "$TRANS_FILE" ] && echo "" > "$TRANS_FILE"
  rm -rf "$TRANS_DIR"

  # 3. Copy into Docker
  docker cp "$META_FILE" youtube_learn-web-1:/tmp/ 2>/dev/null
  docker cp "$TRANS_FILE" youtube_learn-web-1:/tmp/ 2>/dev/null

  # 4. Write import script with video_id baked in
  cat > /tmp/yt_import_run.rb << ENDRUBY
require "json"

video_id = "${VIDEO_ID}"
user = User.first

if user.video_learnings.exists?(youtube_video_id: video_id)
  puts "SKIP"
  exit
end

meta = JSON.parse(File.read("/tmp/yt_meta_#{video_id}.json")) rescue {}
transcript = File.read("/tmp/yt_trans_#{video_id}.txt").strip rescue ""

upload_date = meta["upload_date"].to_s
published = nil
if upload_date.length == 8
  published = Date.new(upload_date[0..3].to_i, upload_date[4..5].to_i, upload_date[6..7].to_i) rescue nil
end

vl = user.video_learnings.new(
  youtube_url: "https://www.youtube.com/watch?v=#{video_id}",
  youtube_video_id: video_id,
  title: meta["title"] || "Unknown",
  channel_name: meta["channel"] || "Unknown",
  description: meta["description"].to_s[0..2000],
  duration_seconds: meta["duration"].to_i > 0 ? meta["duration"].to_i : nil,
  published_at: published,
  transcript_text: transcript.presence,
  status: :extracting,
  processing_progress: transcript.present? ? 30 : 10
)

if vl.save
  Channels::AutoAssign.new(vl).call rescue nil
  puts vl.id
else
  puts "ERR:#{vl.errors.full_messages.join(', ')}"
end

File.delete("/tmp/yt_meta_#{video_id}.json") rescue nil
File.delete("/tmp/yt_trans_#{video_id}.txt") rescue nil
ENDRUBY

  docker cp /tmp/yt_import_run.rb youtube_learn-web-1:/tmp/ 2>/dev/null

  # 5. Run
  RESULT=$(docker compose exec -T web bin/rails runner /tmp/yt_import_run.rb 2>/dev/null | grep -v WARNING | grep -v DETAIL | grep -v HINT | grep -v "^$" | tail -1 | tr -d '\r\n')

  rm -f "$META_FILE" "$TRANS_FILE" /tmp/yt_import_run.rb

  if [ "$RESULT" = "SKIP" ]; then
    echo "skip"
    SKIPPED=$((SKIPPED + 1))
  elif echo "$RESULT" | grep -qE '^[0-9]+$'; then
    echo "ok (id:${RESULT})"
    PROCESSED=$((PROCESSED + 1))
  else
    echo "failed: $RESULT"
    FAILED=$((FAILED + 1))
  fi

  sleep $((DELAY + RANDOM % 4))

  if [ $((LINE_NUM % 50)) -eq 0 ]; then
    echo ""
    echo "--- [${LINE_NUM}/${TOTAL}] ${PROCESSED} ok | ${FAILED} failed | ${SKIPPED} skipped ---"
    echo ""
  fi

done 3< "$QUEUE_FILE"

echo ""
echo "=========================================="
echo "IMPORT COMPLETE"
echo "  Processed: $PROCESSED"
echo "  Failed:    $FAILED"
echo "  Skipped:   $SKIPPED"
echo "=========================================="
