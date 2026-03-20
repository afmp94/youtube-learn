# YouTube Learn

Knowledge extraction and analysis engine for YouTube videos. Processes videos through transcript extraction, frame analysis (Claude Vision), and AI-powered learning extraction to build a searchable knowledge base.

**4,713 videos analyzed** across 14 channels including The Futur, Ali Abdaal, Y Combinator, Alex Hormozi, Greg Isenberg, Lenny's Podcast, and more.

## Tech Stack

- **Ruby on Rails 8.1.2** / Ruby 3.4.7
- **PostgreSQL 17** with pgvector for semantic search
- **Solid Queue** for background jobs
- **Tailwind CSS v4** for frontend
- **Claude Vision API** for video frame analysis
- **OpenAI text-embedding-3-small** for vector embeddings
- **yt-dlp + ffmpeg** for video/frame extraction

## Setup

### Prerequisites

- Docker & Docker Compose
- An Anthropic API key (for video analysis)
- An OpenAI API key (for embeddings)

### Quick Start

```bash
# Clone and start services
docker compose up -d

# Setup database
docker compose exec web bin/rails db:prepare

# Load Solid Queue schema
docker compose exec web bin/rails runner "load Rails.root.join('db/queue_schema.rb')"

# Start the app
docker compose up
```

The app runs on **http://localhost:3001**.

### Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Claude API key for video analysis |
| `OPENAI_API_KEY` | OpenAI API key for embeddings |

## Processing Pipeline

Each video goes through:

1. **Metadata extraction** — title, channel, duration via yt-dlp
2. **Transcript extraction** — YouTube captions or Whisper fallback
3. **Frame extraction** — key frames via ffmpeg
4. **Claude analysis** — summary, key takeaways, concepts, difficulty level, detailed notes
5. **Quote extraction** — notable quotes with speakers and timestamps
6. **Embedding generation** — vector embedding for semantic search

## API

All endpoints require a Bearer token in the `Authorization` header.

### Authentication

```bash
# Generate an API key
docker compose exec web bin/rails runner '
user = User.first
raw_token = ApiKey.generate_token
user.api_keys.create!(
  name: "My API Key",
  token_digest: Digest::SHA256.hexdigest(raw_token),
  token_prefix: raw_token[0..7]
)
puts raw_token
'

# Use it
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3001/api/v1/videos/stats
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/videos` | List videos (filters: `channel`, `tag`, `status`, `difficulty`, `per_page`) |
| GET | `/api/v1/videos/:id` | Full video detail with quotes |
| GET | `/api/v1/videos/stats` | Knowledge base statistics |
| GET | `/api/v1/search?q=...` | Hybrid semantic + fulltext search (params: `limit`, `tags[]`, `channel`, `difficulty`) |
| GET | `/api/v1/channels` | All channels with video counts |
| GET | `/api/v1/channels/:id` | Channel detail with videos |
| GET | `/api/v1/tags` | Tags ranked by usage count |
| GET | `/api/v1/tags/:id` | Tag with associated videos |
| GET | `/api/v1/quotes` | Quotes (filter: `speaker`, `per_page`) |
| GET | `/api/v1/quotes/search?q=...` | Quote text search |
| GET | `/api/v1/concepts` | Aggregated concepts across all videos (param: `min_count`) |
| GET | `/api/v1/content_pieces` | List generated content pieces |
| GET | `/api/v1/content_pieces/:id` | Content piece detail |
| POST | `/api/v1/content_pieces` | Generate content from videos (`video_ids[]`, `platform`, `format`, `title`, `prompt`) |
| GET | `/api/v1/api_keys` | List your API keys |
| POST | `/api/v1/api_keys` | Create new API key (params: `name`) |
| DELETE | `/api/v1/api_keys/:id` | Revoke an API key |

### Rate Limits

- **300 requests / 5 minutes** per API key
- **100 requests / 5 minutes** per IP (fallback)

### Example Responses

**Stats:**
```json
{
  "total_videos": 4713,
  "completed": 4713,
  "total_duration_hours": 401.4,
  "unique_channels": 14,
  "difficulty_breakdown": { "beginner": 2177, "intermediate": 2205, "advanced": 331 },
  "top_channels": { "The Futur": 1067, "Ali Abdaal": 665, "Y Combinator": 586 }
}
```

**Search:**
```bash
curl -H "Authorization: Bearer TOKEN" \
  "http://localhost:3001/api/v1/search?q=pricing+strategy&limit=5&tags[]=sales"
```

## Semantic Search (pgvector)

Uses hybrid Reciprocal Rank Fusion combining pgvector cosine similarity with pg_search fulltext.

### Generate Embeddings

```bash
# Single-record backfill
docker compose exec web bin/rails embeddings:backfill

# Batch backfill (faster for large datasets)
docker compose exec web bin/rails embeddings:batch_backfill
```

New videos get embeddings automatically via `GenerateEmbeddingJob`.

## MCP Server

Exposes the knowledge base to Claude Desktop (or any MCP client) via 8 tools.

### Tools

| Tool | Description |
|------|-------------|
| `search_videos` | Semantic + fulltext hybrid search |
| `get_video` | Full video details by ID |
| `list_channels` | All channels with video counts |
| `get_channel_insights` | Channel profile + recent videos |
| `find_quotes` | Search quotes by text or speaker |
| `get_concepts` | Key concepts ranked by frequency |
| `knowledge_stats` | Overall knowledge base stats |
| `find_related_videos` | Semantically similar videos (requires embeddings) |

### Claude Desktop Configuration

Add to `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "youtube-learn": {
      "command": "docker",
      "args": ["compose", "exec", "-T", "web", "ruby", "script/mcp_server.rb"],
      "cwd": "/Users/afmp/youtube_learn"
    }
  }
}
```

### Running Standalone

```bash
docker compose exec -T web ruby script/mcp_server.rb
```

## Project Structure

```
app/
├── controllers/
│   ├── api/v1/          # API controllers (ActionController::API)
│   │   ├── base_controller.rb    # Auth + pagination
│   │   ├── search_controller.rb  # Hybrid search
│   │   ├── videos_controller.rb  # Videos + stats
│   │   ├── channels_controller.rb
│   │   ├── tags_controller.rb
│   │   ├── quotes_controller.rb
│   │   ├── concepts_controller.rb
│   │   ├── content_pieces_controller.rb
│   │   └── api_keys_controller.rb
│   └── ...              # Web controllers (HTML/Turbo)
├── jobs/
│   ├── process_video_job.rb       # Main pipeline orchestrator
│   ├── extract_quotes_job.rb
│   └── generate_embedding_job.rb
├── models/
│   ├── video_learning.rb  # Core model (has_neighbors :embedding)
│   ├── api_key.rb         # Bearer token auth
│   └── ...
├── services/
│   ├── embeddings/
│   │   ├── generator.rb           # OpenAI client
│   │   └── video_learning_embedder.rb  # Text construction
│   ├── search/
│   │   └── hybrid.rb              # RRF semantic + fulltext
│   └── videos/
│       ├── metadata_extractor.rb
│       ├── transcript_extractor.rb
│       ├── frame_extractor.rb
│       └── claude_analyzer.rb
└── ...
script/
└── mcp_server.rb          # MCP server (fast-mcp, stdio transport)
```
