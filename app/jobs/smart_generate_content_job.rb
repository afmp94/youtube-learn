class SmartGenerateContentJob < ApplicationJob
  queue_as :default

  def perform(user_id:, prompt:, platform:, project_id: nil)
    user = User.find(user_id)

    broadcast_status(user, :generating, prompt: prompt)

    content_piece = Content::SmartGenerationService.new(
      user: user,
      prompt: prompt,
      platform: platform,
      project_id: project_id
    ).call

    broadcast_status(user, :complete, content_piece: content_piece)
  rescue Content::GenerationError => e
    broadcast_status(user, :failed, error_message: e.message, prompt: prompt)
  rescue => e
    Rails.logger.error("SmartGenerateContentJob failed: #{e.class} - #{e.message}")
    broadcast_status(user, :failed, error_message: "Unexpected error: #{e.message}", prompt: prompt)
  end

  private

  def broadcast_status(user, status, content_piece: nil, error_message: nil, prompt: nil)
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user.id}_content",
      target: "content_generation_status",
      partial: "content_pieces/generation_status",
      locals: { status: status, content_piece: content_piece, error_message: error_message }
    )
  end
end
