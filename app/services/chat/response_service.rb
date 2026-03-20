module Chat
  class ResponseService
    # conversation: the Conversation record
    # user_message: the text of the user's question (already saved as a Message by the controller)
    def initialize(conversation, user_message)
      @conversation = conversation
      @user = conversation.user
      @user_message = user_message
    end

    def call
      # 1. Retrieve relevant knowledge
      retrieval = KnowledgeRetriever.new(@user, @user_message).call
      knowledge_context = retrieval[:context]
      source_videos = retrieval[:videos]

      # 2. Build conversation history (all messages so far, including the user message already saved)
      history = @conversation.messages
        .order(created_at: :asc)
        .last(20)

      # 3. Build system prompt
      system_prompt = build_system_prompt(knowledge_context)

      # 4. Build messages array for Claude from conversation history
      messages = build_messages(history)

      # 5. Call Claude API
      result_text = call_claude(system_prompt, messages)

      # 6. Save assistant message with source_video_ids
      assistant_msg = @conversation.messages.create!(
        role: :assistant,
        content: result_text,
        source_video_ids: source_videos.map(&:id)
      )

      # 7. Update conversation title from first question if still default
      if @conversation.messages.count <= 2 && @conversation.title == "New Chat"
        new_title = @user_message.truncate(60)
        @conversation.update(title: new_title)
      end

      @conversation.touch

      assistant_msg
    rescue Chat::Error
      raise
    rescue => e
      raise Chat::Error, "Failed to generate response: #{e.message}"
    end

    private

    def build_system_prompt(knowledge_context)
      prompt = <<~PROMPT
        You are a knowledgeable assistant that helps users explore and understand their personal video learning library. The user has been learning from YouTube videos and you have access to their notes, summaries, and key takeaways.

        Your role:
        - Answer questions based on the user's video knowledge base
        - Cite sources naturally: "According to [video title]..." or "As [channel name] explains..."
        - If you reference specific takeaways, concepts, or notes, mention which video they come from
        - If no relevant knowledge is found in the provided context, say so honestly and suggest what topics the user might want to explore
        - Be conversational, helpful, and concise
        - Use markdown formatting when it helps readability (bold, lists, headers)
        - When comparing ideas across videos, highlight different perspectives

        IMPORTANT: Only use information from the provided knowledge context. Do not make up information that isn't in the user's knowledge base.
      PROMPT

      if knowledge_context.present?
        prompt += <<~CONTEXT

          Here is the relevant knowledge from the user's video library:

          #{knowledge_context}
        CONTEXT
      else
        prompt += <<~EMPTY

          Note: No directly relevant videos were found in the user's knowledge base for this query. Let the user know, and try to be helpful anyway.
        EMPTY
      end

      prompt
    end

    def build_messages(history)
      messages = []

      # Build from conversation history (user message is already included)
      history.each do |msg|
        messages << {
          role: msg.role,
          content: msg.content
        }
      end

      # Ensure we have at least one message
      if messages.empty?
        messages << { role: "user", content: @user_message }
      end

      messages
    end

    def call_claude(system_prompt, messages)
      api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
      raise Chat::Error, "Anthropic API key not configured" if api_key.blank?

      client = Anthropic::Client.new(api_key: api_key)

      response = client.messages.create(
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 4096,
        system: system_prompt,
        messages: messages
      )

      if response.respond_to?(:content)
        block = response.content.is_a?(Array) ? response.content.first : response.content
        block.respond_to?(:text) ? block.text : block["text"]
      else
        response.dig("content", 0, "text")
      end
    end
  end
end
