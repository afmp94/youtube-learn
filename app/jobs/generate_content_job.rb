class GenerateContentJob < ApplicationJob
  queue_as :default

  def perform(user_id:, video_learning_ids:, platform:, content_format:, template_name: nil)
    user = User.find(user_id)

    broadcast_status(user, :generating)

    content_piece = Content::GenerationService.new(
      user: user,
      video_learning_ids: video_learning_ids,
      platform: platform,
      content_format: content_format,
      template_name: template_name
    ).call

    broadcast_status(user, :complete, content_piece: content_piece)
  rescue Content::GenerationError => e
    handle_failure(user, video_learning_ids, platform, content_format, e.message)
  rescue => e
    Rails.logger.error("GenerateContentJob failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    handle_failure(user, video_learning_ids, platform, content_format, "Unexpected error: #{e.message}")
  end

  private

  def handle_failure(user, video_learning_ids, platform, content_format, error_message)
    content_piece = ContentPiece.create!(
      user: user,
      platform: platform,
      content_format: content_format,
      title: "Failed Generation",
      body: "Generation failed: #{error_message}",
      status: :draft
    )

    # Link source videos even on failure so the user can retry
    Array(video_learning_ids).each do |vl_id|
      ContentPieceSource.create(content_piece: content_piece, video_learning_id: vl_id)
    rescue ActiveRecord::RecordInvalid
      next
    end

    broadcast_status(user, :failed, content_piece: content_piece, error: error_message)
  end

  def broadcast_status(user, status, content_piece: nil, error: nil)
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user.id}_content",
      target: "content_generation_status",
      partial: "content_pieces/generation_status",
      locals: { status: status, content_piece: content_piece, error: error }
    )
  end
end
