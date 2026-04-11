# YouTube Learn

Rails 8.1.2 app that extracts learnings from YouTube videos using Claude's vision API, with a Virality Lab for content optimization.

## Tech Stack

- **Backend**: Rails 8.1.2, Ruby 3.4.7, PostgreSQL 17, Solid Queue
- **Frontend**: Tailwind CSS v4, Hotwire (Turbo + Stimulus), Import Maps
- **AI**: `anthropic` gem (Claude API), TRIBE v2 (brain encoding)
- **Gems**: Pagy v9, pg_search, redcarpet, prawn, youtube-transcript-rb
- **Tools**: yt-dlp + ffmpeg for video/frame extraction

## Architecture

### Video Pipeline
`ProcessVideoJob` → MetadataExtractor → TranscriptExtractor → FrameExtractor → ClaudeAnalyzer

### Virality Lab (`/lab`)
Analyzes content for viral potential using:
1. **Claude AI** — scores 8 virality dimensions (hook_power, emotional_resonance, shareability, practical_value, storytelling, novelty, platform_fit, controversy)
2. **TRIBE v2** — predicts brain fMRI responses, maps 22 HCP brain regions to 6 functional clusters

Flow: `ViralityAnalysisJob` → Claude analysis → TRIBE v2 brain analysis (non-blocking) → Turbo Stream updates

### Key Services
- `app/services/videos/` — Video processing pipeline
- `app/services/virality/analysis_service.rb` — Claude-based virality scoring
- `app/services/virality/brain_analysis_service.rb` — TRIBE v2 subprocess bridge
- `script/tribe_predict.py` — Python bridge script for TRIBE v2

## Development Setup

### Docker (primary)
```bash
docker compose up -d
# App at http://localhost:3001
```

If `web` exits with stale PID: `rm -f tmp/pids/server.pid && docker compose up -d web`

### Solid Queue schema
```bash
docker compose exec web rails runner "load Rails.root.join('db/queue_schema.rb')"
```

### Environment Variables
- `ANTHROPIC_API_KEY` — Claude API key (or use `credentials.dig(:anthropic, :api_key)`)
- `TRIBE_ENABLED` — Enable/disable brain analysis (default: true)
- `TRIBE_PYTHON_PATH` — Path to tribev2 venv Python (default: `/Users/afmp/Projects/tribev2/.venv/bin/python`)
- `TRIBE_CACHE_FOLDER` — TRIBE v2 model cache (default: `/Users/afmp/Projects/tribev2/cache`)
- `TRIBE_TIMEOUT` — Brain analysis timeout in seconds (default: 120)

## TRIBE v2 Setup (Brain Encoding)

### Prerequisites
TRIBE v2 runs on the host machine (not Docker) because it requires Apple MPS (Metal GPU).

### Installation
```bash
# Clone repo (already done at /Users/afmp/Projects/tribev2/)
cd /Users/afmp/Projects/tribev2
python3.12 -m venv .venv
.venv/bin/pip install -e ".[plotting]"
.venv/bin/pip install torchaudio whisperx

# HuggingFace auth (required for LLaMA 3.2-3B gated model)
# Token stored at ~/.cache/huggingface/token
# Account: afmp94
# Must have access to: meta-llama/Llama-3.2-3B, facebook/tribev2
```

### Required Patches (already applied to local repo)
Three patches in `/Users/afmp/Projects/tribev2/tribev2/eventstransforms.py`:

1. **WhisperX path** — Use venv whisperx instead of `uvx` (which creates broken Python 3.14 env):
   ```python
   # Line ~113: Replace "uvx", "whisperx" with venv binary detection
   venv_dir = Path(_sys.executable).parent
   venv_whisperx = venv_dir / "whisperx"
   if venv_whisperx.exists(): cmd = [str(venv_whisperx)]
   else: cmd = ["uvx", "whisperx"]
   ```

2. **Compute type** — float16 doesn't work on CPU:
   ```python
   # Line ~108: Change from always float16
   compute_type = "float16" if device == "cuda" else "int8"
   ```

3. **Device override** — Done in `script/tribe_predict.py`, overrides extractors from `cuda` to `mps`

### Testing TRIBE v2
```bash
cd /Users/afmp/Projects/tribev2
PYTORCH_ENABLE_MPS_FALLBACK=1 .venv/bin/python /Users/afmp/youtube_learn/script/tribe_predict.py \
  --text "Your content to analyze" \
  --output-dir /tmp/tribe_test \
  --skip-images
```

### Performance (M2 Max, 32GB)
- First run: ~3-5 min (downloads/caches models)
- Cached runs: ~30-60s
- Brain analysis is non-blocking — Claude analysis completes first, brain analysis follows

### Limitations
- Brain analysis only runs on host (not in Docker) — requires Apple MPS
- In Docker, brain_status is set to `brain_skipped` (graceful degradation)
- Text input goes through TTS → WhisperX → feature extraction pipeline

## Routes
- `/` — Dashboard
- `/videos` — Video learnings
- `/lab` — Virality Lab
- `/content` — Content pieces
- `/quotes` — Quotes
- `/chat` — AI conversations

## Testing
```bash
docker compose exec web bin/rails test
```
