class ChatResponseJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, user_message)
    conversation = Conversation.find(conversation_id)

    begin
      assistant_message = Chat::ResponseService.new(conversation, user_message).call

      # Broadcast the assistant message
      Turbo::StreamsChannel.broadcast_append_to(
        "conversation_#{conversation.id}",
        target: "messages",
        partial: "conversations/message",
        locals: { message: assistant_message }
      )

      # Remove the typing indicator
      Turbo::StreamsChannel.broadcast_remove_to(
        "conversation_#{conversation.id}",
        target: "typing_indicator"
      )

      # Update the sidebar item if visible
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{conversation.user_id}_conversations",
        target: "conversation_#{conversation.id}_sidebar",
        partial: "conversations/sidebar_item",
        locals: { conversation: conversation, active: true }
      )
    rescue Chat::Error => e
      broadcast_error(conversation, e.message)
    rescue => e
      Rails.logger.error("ChatResponseJob failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      broadcast_error(conversation, "Something went wrong. Please try again.")
    end
  end

  private

  def broadcast_error(conversation, error_message)
    # Remove the typing indicator
    Turbo::StreamsChannel.broadcast_remove_to(
      "conversation_#{conversation.id}",
      target: "typing_indicator"
    )

    # Broadcast an error message
    Turbo::StreamsChannel.broadcast_append_to(
      "conversation_#{conversation.id}",
      target: "messages",
      html: <<~HTML
        <div class="flex justify-start mb-4">
          <div class="max-w-[80%] px-4 py-3 rounded-2xl rounded-bl-md bg-red-50 border border-red-200 text-red-700 text-sm">
            #{ERB::Util.html_escape(error_message)}
          </div>
        </div>
      HTML
    )
  end
end
