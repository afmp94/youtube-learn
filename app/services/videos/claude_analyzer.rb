module Videos
  class ClaudeAnalyzer
    def initialize(video_learning)
      @video_learning = video_learning
      @user = video_learning.user
    end

    def call
      content_blocks = build_content_blocks
      system_prompt = build_system_prompt

      api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
      raise Videos::AnalysisError, "Anthropic API key not configured" if api_key.blank?

      client = Anthropic::Client.new(api_key: api_key)

      response = client.messages.create(
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 8192,
        system: system_prompt,
        messages: [{ role: "user", content: content_blocks }]
      )

      result_text = if response.respond_to?(:content)
        block = response.content.is_a?(Array) ? response.content.first : response.content
        block.respond_to?(:text) ? block.text : block["text"]
      else
        response.dig("content", 0, "text")
      end
      parsed = parse_response(result_text)

      @video_learning.update!(
        summary: parsed[:summary],
        key_takeaways: parsed[:key_takeaways],
        concepts: parsed[:concepts],
        detailed_notes: parsed[:detailed_notes],
        difficulty_level: parsed[:difficulty_level],
        estimated_read_time: parsed[:estimated_read_time]
      )
    rescue Videos::AnalysisError
      raise
    rescue JSON::ParserError => e
      raise Videos::AnalysisError, "Failed to parse Claude response: #{e.message}"
    rescue => e
      raise Videos::AnalysisError, "Claude API error: #{e.message}"
    end

    private

    def build_system_prompt
      learning_context = Videos::LearningContext.new(@user).call

      prompt = <<~PROMPT
        You are an expert educational content analyzer. Analyze the video transcript and visual frames to create comprehensive learning materials.

      PROMPT

      if learning_context.present?
        prompt += <<~CONTEXT
          The user has previously learned these topics - reference and build on them when relevant (e.g., "This builds on [concept] you learned earlier"):

          #{learning_context}

        CONTEXT
      end

      prompt += <<~FORMAT
        Output valid JSON with this exact structure:
        {
          "summary": "2-3 paragraph summary of the video content",
          "key_takeaways": ["takeaway 1", "takeaway 2", ...],
          "concepts": [
            {"name": "concept name", "description": "brief description", "importance": "high/medium/low"}
          ],
          "detailed_notes": "Comprehensive markdown-formatted notes with headers, bullet points, and code blocks if applicable",
          "difficulty_level": "beginner/intermediate/advanced",
          "estimated_read_time": 5,
          "suggested_tags": ["tag1", "tag2"]
        }
      FORMAT

      prompt
    end

    def build_content_blocks
      blocks = []

      # Add frame images
      frames = @video_learning.frames.ordered.limit(20)
      frames.each do |frame|
        next unless frame.image.attached?

        image_data = frame.image.download
        base64 = Base64.strict_encode64(image_data)
        media_type = frame.image.content_type || "image/jpeg"

        blocks << {
          type: "image",
          source: { type: "base64", media_type: media_type, data: base64 }
        }
        blocks << {
          type: "text",
          text: "[Frame at #{frame.formatted_timestamp}]"
        }
      end

      # Add transcript
      transcript = @video_learning.transcript_text
      if transcript.present?
        blocks << {
          type: "text",
          text: "VIDEO TRANSCRIPT:\n\n#{transcript.truncate(100_000)}"
        }
      end

      # Add video metadata
      blocks << {
        type: "text",
        text: "VIDEO INFO:\nTitle: #{@video_learning.title}\nChannel: #{@video_learning.channel_name}\nDuration: #{@video_learning.formatted_duration}"
      }

      blocks
    end

    def parse_response(text)
      # Extract JSON from potential markdown code blocks
      json_text = if text.include?("```")
        text.gsub(/\A.*?```(?:json)?\s*\n/m, "").gsub(/\n?\s*```.*\z/m, "")
      else
        text
      end.strip

      # Try parsing, if truncated attempt to repair
      begin
        data = JSON.parse(json_text)
      rescue JSON::ParserError
        # Try closing open strings and braces
        repaired = json_text
        repaired += '"' if repaired.count('"').odd?
        # Close any open arrays/objects
        open_braces = repaired.count("{") - repaired.count("}")
        open_brackets = repaired.count("[") - repaired.count("]")
        repaired += "]" * open_brackets if open_brackets > 0
        repaired += "}" * open_braces if open_braces > 0
        data = JSON.parse(repaired)
      end

      {
        summary: data["summary"],
        key_takeaways: data["key_takeaways"] || [],
        concepts: data["concepts"] || [],
        detailed_notes: data["detailed_notes"],
        difficulty_level: data["difficulty_level"] || "intermediate",
        estimated_read_time: data["estimated_read_time"]&.to_i || 5,
        suggested_tags: data["suggested_tags"] || []
      }
    end
  end
end
