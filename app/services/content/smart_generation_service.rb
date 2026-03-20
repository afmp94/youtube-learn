module Content
  class SmartGenerationService
    def initialize(user:, prompt:, platform: "linkedin", project_id: nil)
      @user = user
      @prompt = prompt
      @platform = platform.to_s
      @project = project_id ? user.projects.find_by(id: project_id) : nil
    end

    def call
      raise Content::GenerationError, "Tell me what you want to create" if @prompt.blank?
      raise Content::GenerationError, "No user provided" if @user.nil?

      # 1. Search the knowledge base
      if @project
        retrieval = project_scoped_retrieval
      else
        retrieval = Chat::KnowledgeRetriever.new(@user, @prompt).call
      end
      videos = retrieval[:videos]
      knowledge_context = retrieval[:context]

      # 2. If no relevant videos found, try broader search
      if videos.empty?
        videos = @user.video_learnings.completed.recent.limit(10).to_a
        knowledge_context = compile_fallback_knowledge(videos)
      end

      raise Content::GenerationError, "You don't have any completed videos yet. Process some videos first!" if videos.empty?

      # 3. Generate the content with a single Claude call
      platform_guidelines = PlatformPrompts.for(@platform)
      system_prompt = build_system_prompt(platform_guidelines)
      user_content = build_user_content(knowledge_context)

      generated = call_claude(system_prompt, user_content)

      # 4. Parse the structured response
      parsed = parse_response(generated)

      # 5. Create the content piece
      content_piece = create_content_piece(parsed)
      create_sources(content_piece, videos)

      content_piece
    rescue Content::GenerationError
      raise
    rescue => e
      raise Content::GenerationError, "Smart generation failed: #{e.message}"
    end

    private

    def build_system_prompt(platform_guidelines)
      <<~SYSTEM
        You are a world-class content creator who sounds genuinely human. You never sound like AI.
        You write like someone who actually learned something and can't wait to share it.

        Your writing style:
        - Conversational, like talking to a smart friend
        - Specific and concrete — use real details from the source material
        - Has personality — opinions, reactions, "here's what surprised me"
        - References experts naturally ("I was studying [expert]'s take on X and...")
        - Never generic, never corporate, never boring
        - Reads like something a real person wrote after being genuinely excited about an insight

        #{platform_guidelines}
        #{project_context_prompt}

        IMPORTANT: Output your response in this exact format:

        TITLE: [A compelling title or hook — one line]
        FORMAT: [post|thread|script|article|carousel_outline|hooks_list]
        ---
        [The actual content here. Ready to publish. No meta-commentary.]

        The FORMAT should be what makes most sense for the platform and the user's request.
        For LinkedIn: usually "post" or "carousel_outline"
        For Twitter: usually "thread" or "post"
        For YouTube: always "script"
        For Blog: always "article"
        For Newsletter: always "article"
      SYSTEM
    end

    def build_user_content(knowledge_context)
      parts = []
      parts << "THE CREATOR'S REQUEST:"
      parts << @prompt
      parts << ""
      parts << "PLATFORM: #{@platform}"
      parts << ""

      if knowledge_context.present?
        parts << "KNOWLEDGE BASE (use this as source material — don't copy, synthesize and make it yours):"
        parts << ""
        parts << knowledge_context
      end

      parts.join("\n")
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

    def parse_response(text)
      title = nil
      content_format = default_format
      body = text

      # Try to extract structured header
      if text.include?("---")
        header, _, content = text.partition("---")
        body = content.strip

        header.lines.each do |line|
          if line.strip.start_with?("TITLE:")
            title = line.sub("TITLE:", "").strip
          elsif line.strip.start_with?("FORMAT:")
            fmt = line.sub("FORMAT:", "").strip.downcase
            content_format = fmt if ContentPiece.content_formats.key?(fmt)
          end
        end
      end

      # Fallback title from first line
      if title.blank? && body.present?
        first_line = body.lines.first&.strip
        if first_line&.start_with?("#")
          title = first_line.gsub(/^#+\s*/, "").truncate(255)
        elsif first_line && first_line.length <= 120
          title = first_line.truncate(255)
        end
      end

      title = "#{@platform.titleize} content" if title.blank?

      { title: title, content_format: content_format, body: body }
    end

    def default_format
      case @platform
      when "linkedin" then "post"
      when "twitter" then "thread"
      when "youtube_script" then "script"
      when "blog" then "article"
      when "newsletter" then "article"
      else "post"
      end
    end

    def create_content_piece(parsed)
      ContentPiece.create!(
        user: @user,
        project: @project,
        platform: @platform,
        content_format: parsed[:content_format],
        title: parsed[:title],
        body: parsed[:body],
        status: :draft,
        generation_prompt: @prompt
      )
    end

    def create_sources(content_piece, videos)
      videos.first(10).each do |video|
        ContentPieceSource.create!(
          content_piece: content_piece,
          video_learning_id: video.id
        )
      rescue ActiveRecord::RecordInvalid
        next
      end
    end

    def project_scoped_retrieval
      project_videos = @project.video_learnings.completed
      videos = begin
        project_videos.search(@prompt).limit(10).to_a
      rescue PgSearch::EmptyQueryError
        project_videos.recent.limit(10).to_a
      end
      videos = project_videos.recent.limit(10).to_a if videos.empty?

      knowledge_entries = @project.knowledge_entries.recent.limit(20)
      context = compile_project_context(videos, knowledge_entries)
      { videos: videos, context: context }
    end

    def compile_project_context(videos, knowledge_entries)
      parts = []
      if @project.brief.present?
        parts << "PROJECT BRIEF/GOAL:\n#{@project.brief}"
      end
      if knowledge_entries.any?
        parts << "PROJECT KNOWLEDGE BASE:"
        knowledge_entries.each do |entry|
          parts << "[#{entry.entry_type.titleize}: #{entry.title}]"
          parts << entry.body.to_s.truncate(2000) if entry.body.present?
        end
      end
      if videos.any?
        parts << "VIDEO KNOWLEDGE:"
        videos.each do |video|
          video_parts = ["[From: #{video.title} by #{video.channel_name}]"]
          video_parts << "Summary: #{video.summary}" if video.summary.present?
          if video.key_takeaways.present?
            video_parts << "Takeaways: #{video.key_takeaways.first(5).join('; ')}"
          end
          parts << video_parts.join("\n")
        end
      end
      parts.join("\n\n---\n\n").truncate(30_000)
    end

    def project_context_prompt
      if @project&.brief.present?
        "\n\nPROJECT CONTEXT: Creating content for project \"#{@project.name}\". Goal: #{@project.brief}. Keep content aligned with this project's purpose."
      else
        ""
      end
    end

    def compile_fallback_knowledge(videos)
      return "" if videos.empty?

      videos.map { |vl|
        parts = ["[From: #{vl.title} by #{vl.channel_name}]"]
        parts << "Summary: #{vl.summary}" if vl.summary.present?
        if vl.key_takeaways.present?
          parts << "Takeaways: #{vl.key_takeaways.first(5).join('; ')}"
        end
        parts.join("\n")
      }.join("\n\n---\n\n").truncate(30_000)
    end
  end
end
