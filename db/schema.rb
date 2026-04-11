# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_11_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "name", null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.string "token_prefix", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
    t.index ["token_prefix"], name: "index_api_keys_on_token_prefix"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "bulk_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "import_type", default: 0, null: false
    t.integer "processed_count", default: 0, null: false
    t.string "source_url", null: false
    t.integer "status", default: 0, null: false
    t.string "title"
    t.integer "total_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.jsonb "video_urls", default: []
    t.index ["user_id", "status"], name: "index_bulk_imports_on_user_id_and_status"
    t.index ["user_id"], name: "index_bulk_imports_on_user_id"
  end

  create_table "channels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.text "notes"
    t.string "thumbnail_url"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "youtube_channel_id"
    t.index ["user_id", "name"], name: "index_channels_on_user_id_and_name", unique: true
    t.index ["user_id", "youtube_channel_id"], name: "index_channels_on_user_id_and_youtube_channel_id", unique: true, where: "(youtube_channel_id IS NOT NULL)"
    t.index ["user_id"], name: "index_channels_on_user_id"
  end

  create_table "collection_video_learnings", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.bigint "video_learning_id", null: false
    t.index ["collection_id", "video_learning_id"], name: "idx_collection_video_learnings_unique", unique: true
    t.index ["collection_id"], name: "index_collection_video_learnings_on_collection_id"
    t.index ["video_learning_id"], name: "index_collection_video_learnings_on_video_learning_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_collections_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "content_piece_sources", force: :cascade do |t|
    t.bigint "content_piece_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "video_learning_id", null: false
    t.index ["content_piece_id", "video_learning_id"], name: "idx_content_piece_sources_unique", unique: true
    t.index ["content_piece_id"], name: "index_content_piece_sources_on_content_piece_id"
    t.index ["video_learning_id"], name: "index_content_piece_sources_on_video_learning_id"
  end

  create_table "content_pieces", force: :cascade do |t|
    t.text "body"
    t.bigint "collection_id"
    t.integer "content_format", null: false
    t.datetime "created_at", null: false
    t.text "generation_prompt"
    t.integer "platform", null: false
    t.bigint "project_id"
    t.integer "status", default: 0, null: false
    t.string "template_name"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["collection_id"], name: "index_content_pieces_on_collection_id"
    t.index ["project_id"], name: "index_content_pieces_on_project_id"
    t.index ["user_id", "platform"], name: "index_content_pieces_on_user_id_and_platform"
    t.index ["user_id", "status"], name: "index_content_pieces_on_user_id_and_status"
    t.index ["user_id"], name: "index_content_pieces_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_conversations_on_project_id"
    t.index ["user_id", "created_at"], name: "index_conversations_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "frames", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position"
    t.float "timestamp_seconds"
    t.datetime "updated_at", null: false
    t.bigint "video_learning_id", null: false
    t.index ["video_learning_id"], name: "index_frames_on_video_learning_id"
  end

  create_table "knowledge_entries", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "entry_type", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.bigint "project_id", null: false
    t.string "source_url"
    t.text "summary"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id", "entry_type"], name: "index_knowledge_entries_on_project_id_and_entry_type"
    t.index ["project_id"], name: "index_knowledge_entries_on_project_id"
    t.index ["user_id", "created_at"], name: "index_knowledge_entries_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_knowledge_entries_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", null: false
    t.jsonb "source_video_ids", default: []
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "project_video_learnings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "video_learning_id", null: false
    t.index ["project_id", "video_learning_id"], name: "idx_project_video_learnings_unique", unique: true
    t.index ["project_id"], name: "index_project_video_learnings_on_project_id"
    t.index ["video_learning_id"], name: "index_project_video_learnings_on_video_learning_id"
  end

  create_table "projects", force: :cascade do |t|
    t.text "brief"
    t.string "color", default: "indigo"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_projects_on_user_id_and_name", unique: true
    t.index ["user_id", "status"], name: "index_projects_on_user_id_and_status"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.text "context"
    t.datetime "created_at", null: false
    t.string "speaker"
    t.text "text", null: false
    t.float "timestamp_seconds"
    t.datetime "updated_at", null: false
    t.bigint "video_learning_id", null: false
    t.index ["video_learning_id", "timestamp_seconds"], name: "index_quotes_on_video_learning_id_and_timestamp_seconds"
    t.index ["video_learning_id"], name: "index_quotes_on_video_learning_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "video_learning_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "video_learning_id", null: false
    t.index ["tag_id"], name: "index_video_learning_tags_on_tag_id"
    t.index ["video_learning_id", "tag_id"], name: "index_video_learning_tags_on_video_learning_id_and_tag_id", unique: true
    t.index ["video_learning_id"], name: "index_video_learning_tags_on_video_learning_id"
  end

  create_table "video_learnings", force: :cascade do |t|
    t.bigint "bulk_import_id"
    t.bigint "channel_id"
    t.string "channel_name"
    t.jsonb "concepts"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "detailed_notes"
    t.string "difficulty_level"
    t.integer "duration_seconds"
    t.vector "embedding", limit: 768
    t.datetime "embedding_generated_at"
    t.text "error_message"
    t.integer "estimated_read_time"
    t.jsonb "key_takeaways"
    t.integer "processing_progress", default: 0, null: false
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.text "summary"
    t.string "thumbnail_url"
    t.string "title"
    t.jsonb "transcript_data"
    t.text "transcript_text"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "youtube_url"
    t.string "youtube_video_id"
    t.index ["bulk_import_id"], name: "index_video_learnings_on_bulk_import_id"
    t.index ["channel_id"], name: "index_video_learnings_on_channel_id"
    t.index ["embedding"], name: "index_video_learnings_on_embedding", opclass: :vector_cosine_ops, using: :hnsw
    t.index ["status"], name: "index_video_learnings_on_status"
    t.index ["user_id", "youtube_video_id"], name: "index_video_learnings_on_user_id_and_youtube_video_id", unique: true
    t.index ["user_id"], name: "index_video_learnings_on_user_id"
  end

  create_table "virality_analyses", force: :cascade do |t|
    t.bigint "analyzable_id"
    t.string "analyzable_type"
    t.jsonb "brain_data", default: {}
    t.text "brain_error_message"
    t.integer "brain_status", default: 0
    t.datetime "created_at", null: false
    t.jsonb "dimension_details", default: {}
    t.jsonb "dimension_scores", default: {}
    t.text "error_message"
    t.text "improvements"
    t.text "input_text"
    t.integer "input_type", default: 0, null: false
    t.text "overall_assessment"
    t.integer "overall_score"
    t.integer "status", default: 0, null: false
    t.text "strengths"
    t.string "target_platform"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["analyzable_type", "analyzable_id"], name: "index_virality_analyses_on_analyzable_type_and_analyzable_id"
    t.index ["user_id", "created_at"], name: "index_virality_analyses_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_virality_analyses_on_user_id_and_status"
    t.index ["user_id"], name: "index_virality_analyses_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_keys", "users"
  add_foreign_key "bulk_imports", "users"
  add_foreign_key "channels", "users"
  add_foreign_key "collection_video_learnings", "collections"
  add_foreign_key "collection_video_learnings", "video_learnings"
  add_foreign_key "collections", "users"
  add_foreign_key "content_piece_sources", "content_pieces"
  add_foreign_key "content_piece_sources", "video_learnings"
  add_foreign_key "content_pieces", "collections"
  add_foreign_key "content_pieces", "projects"
  add_foreign_key "content_pieces", "users"
  add_foreign_key "conversations", "projects"
  add_foreign_key "conversations", "users"
  add_foreign_key "frames", "video_learnings"
  add_foreign_key "knowledge_entries", "projects"
  add_foreign_key "knowledge_entries", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "project_video_learnings", "projects"
  add_foreign_key "project_video_learnings", "video_learnings"
  add_foreign_key "projects", "users"
  add_foreign_key "quotes", "video_learnings"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "video_learning_tags", "tags"
  add_foreign_key "video_learning_tags", "video_learnings"
  add_foreign_key "video_learnings", "bulk_imports"
  add_foreign_key "video_learnings", "channels"
  add_foreign_key "video_learnings", "users"
  add_foreign_key "virality_analyses", "users"
end
