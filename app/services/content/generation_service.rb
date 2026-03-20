module Content
  class GenerationService
    def initialize(user:, video_learning_ids:, platform:, content_format:, template_name: nil)
      @user = user
      @video_learning_ids = Array(video_learning_ids).map(&:to_i)
      @platform = platform.to_s
      @content_format = content_format.to_s
      @template_name = template_name
    end

    def call
      validate_inputs!

      knowledge = compile_knowledge
      platform_guidelines = PlatformPrompts.for(@platform)
      template = resolve_template
      system_prompt = build_system_prompt(platform_guidelines, template)
      user_content = build_user_content(knowledge)

      generated_body = call_claude(system_prompt, user_content)

      content_piece = create_content_piece(generated_body, template)
      create_sources(content_piece)

      content_piece
    rescue Content::GenerationError
      raise
    rescue => e
      raise Content::GenerationError, "Content generation failed: #{e.message}"
    end

    private

    def validate_inputs!
      raise Content::GenerationError, "User is required" if @user.nil?
      raise Content::GenerationError, "At least one video learning is required" if @video_learning_ids.empty?

      unless ContentPiece.platforms.key?(@platform)
        raise Content::GenerationError, "Invalid platform: #{@platform}. Valid: #{ContentPiece.platforms.keys.join(', ')}"
      end

      unless ContentPiece.content_formats.key?(@content_format)
        raise Content::GenerationError, "Invalid content format: #{@content_format}. Valid: #{ContentPiece.content_formats.keys.join(', ')}"
      end
    end

    def compile_knowledge
      compiler = KnowledgeCompiler.new(video_learning_ids: @video_learning_ids)
      @compiler = compiler
      compiler.call
    end

    def resolve_template
      if @template_name.present?
        TemplateRegistry.find(@template_name) || TemplateRegistry.default_for(@platform, @content_format)
      else
        TemplateRegistry.default_for(@platform, @content_format)
      end
    end

    def build_system_prompt(platform_guidelines, template)
      prompt = <<~SYSTEM
        You are an expert content creator who transforms knowledge from video learnings into high-quality, platform-specific content. You write in first person as a knowledgeable professional sharing genuine insights they've learned.

        Your content should:
        - Be ready to post/publish with minimal editing
        - Reference source material naturally without feeling like a book report
        - Provide genuine value to the reader
        - Match the voice and conventions of the target platform
        - Be specific and concrete, not generic or vague

      SYSTEM

      prompt += platform_guidelines + "\n"

      if template
        filled = fill_template(template.prompt_template)
        prompt += "\nCONTENT TEMPLATE INSTRUCTIONS:\n#{filled}\n"
      else
        prompt += <<~DEFAULT

          CONTENT INSTRUCTIONS:
          Create a #{@content_format} for #{@platform}. Use the source knowledge to produce
          engaging, valuable content appropriate for the platform. Write in first person,
          reference the source experts naturally, and make it ready to publish.

        DEFAULT
      end

      prompt
    end

    def fill_template(prompt_template)
      expert_names = @compiler&.expert_names&.join(", ") || "the expert(s)"
      topic = @compiler&.topic_summary || "the topic"
      platform_guidelines = "" # Already included in system prompt

      prompt_template
        .gsub("{{expert_names}}", expert_names)
        .gsub("{{topic}}", topic)
        .gsub("{{platform_guidelines}}", platform_guidelines)
    end

    def build_user_content(knowledge)
      "Here is the source knowledge to create content from:\n\n#{knowledge}"
    end

    def call_claude(system_prompt, user_content)
      api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
      raise Content::GenerationError, "Anthropic API key not configured" if api_key.blank?

      client = Anthropic::Client.new(api_key: api_key)

      response = client.messages.create(
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 8192,
        system: system_prompt,
        messages: [{ role: "user", content: user_content }]
      )

      result_text = if response.respond_to?(:content)
        block = response.content.is_a?(Array) ? response.content.first : response.content
        block.respond_to?(:text) ? block.text : block["text"]
      else
        response.dig("content", 0, "text")
      end

      raise Content::GenerationError, "Empty response from Claude" if result_text.blank?

      result_text
    end

    def create_content_piece(body, template)
      ContentPiece.create!(
        user: @user,
        platform: @platform,
        content_format: @content_format,
        title: extract_title(body),
        body: body,
        status: :draft,
        template_name: template&.key,
        generation_prompt: template&.prompt_template
      )
    end

    def extract_title(body)
      # Try to extract a title from the generated content
      first_line = body.lines.first&.strip

      if first_line&.start_with?("#")
        # Markdown header
        first_line.gsub(/^#+\s*/, "").truncate(255)
      elsif first_line && first_line.length <= 120
        # Short first line is likely a title or hook
        first_line.truncate(255)
      else
        # Generate a default title
        "#{@platform.titleize} #{@content_format.titleize}: #{@compiler&.topic_summary}".truncate(255)
      end
    end

    def create_sources(content_piece)
      @video_learning_ids.each do |vl_id|
        ContentPieceSource.create!(
          content_piece: content_piece,
          video_learning_id: vl_id
        )
      rescue ActiveRecord::RecordNotFound
        # Skip if video learning was deleted between validation and source creation
        next
      end
    end
  end
end
