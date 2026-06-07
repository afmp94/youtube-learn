module Virality
  class AnalysisService
    DIMENSION_WEIGHTS = {
      "hook_power" => 0.20,
      "emotional_resonance" => 0.15,
      "shareability" => 0.15,
      "practical_value" => 0.12,
      "storytelling" => 0.12,
      "novelty" => 0.10,
      "platform_fit" => 0.10,
      "controversy" => 0.06
    }.freeze

    def initialize(user:, input_text:, input_type:, target_platform: nil, analyzable: nil)
      @user = user
      @input_text = input_text
      @input_type = input_type.to_s
      @target_platform = target_platform
      @analyzable = analyzable
    end

    def call
      validate!
      raw_response = call_claude(build_system_prompt, build_user_content)
      parsed = parse_response(raw_response)
      build_result(parsed)
    end

    private

    def validate!
      raise Virality::Error, "No user provided" if @user.nil?
      raise Virality::Error, "No content provided for analysis" if @input_text.blank?
    end

    def build_system_prompt
      <<~SYSTEM
        You are ViralityLab AI, an expert content virality prediction engine.
        You analyze content, ideas, and strategies across 8 "virality dimensions" and predict their potential to spread and engage audiences.

        DIMENSIONS (score each 0-100):

        1. HOOK POWER: How compelling is the opening? Does it stop the scroll? A great hook creates instant curiosity or tension.
        2. EMOTIONAL RESONANCE: What emotions does it trigger? Content that makes people feel something strongly (awe, anger, joy, surprise) gets shared more.
        3. SHAREABILITY: Social currency. Would people share this to look smart, helpful, or insightful? Does it make the sharer look good?
        4. PRACTICAL VALUE: Can the audience DO something with this? Actionable advice, frameworks, and tools spread because they're useful.
        5. STORYTELLING: Is there a narrative arc? Personal stories, transformations, before/after, conflict-resolution structures are powerful.
        6. NOVELTY: Is this genuinely new, surprising, or a fresh take? Or is it recycled conventional wisdom everyone has seen before?
        7. PLATFORM FIT: How well does the format, tone, length, and style match the target platform and its audience expectations?
        8. CONTROVERSY: Does it challenge the status quo or conventional thinking? Thought-provoking (not toxic) contrarian views spark discussion.

        SCORING GUIDELINES:
        - 0-20: Very weak. Major gaps that would prevent engagement.
        - 21-40: Below average. Significant room for improvement.
        - 41-60: Average. Solid but not exceptional. Unlikely to break out.
        - 61-80: Strong. Above average, good chance of strong engagement.
        - 81-100: Exceptional. Top 5% viral potential in this dimension.

        Be honest and critical. Most content should score in the 40-70 range. Only truly exceptional content scores 80+.

        RESPOND WITH ONLY VALID JSON. No markdown code fences, no text before or after. The JSON must follow this exact schema:

        {
          "dimensions": {
            "hook_power": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" },
            "emotional_resonance": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" },
            "shareability": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" },
            "practical_value": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" },
            "storytelling": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" },
            "novelty": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" },
            "platform_fit": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" },
            "controversy": { "score": 0, "summary": "one sentence", "suggestion": "one sentence improvement" }
          },
          "overall_assessment": "2-3 sentences summarizing the viral potential",
          "strengths": ["strength 1", "strength 2", "strength 3"],
          "improvements": ["improvement 1", "improvement 2", "improvement 3"]
        }
      SYSTEM
    end

    def build_user_content
      parts = []

      case @input_type
      when "content_piece"
        parts << "CONTENT TYPE: Published content piece"
        parts << "PLATFORM: #{@target_platform}" if @target_platform.present?
      when "video_learning"
        parts << "CONTENT TYPE: Video learning analysis — evaluate which concepts and takeaways would make the most viral content"
      when "strategy"
        parts << "CONTENT TYPE: Marketing strategy — predict audience reaction and engagement potential"
      else
        parts << "CONTENT TYPE: Free-form content or idea"
      end

      parts << "TARGET PLATFORM: #{@target_platform}" if @target_platform.present? && @input_type != "content_piece"
      parts << ""
      parts << "CONTENT TO ANALYZE:"
      parts << @input_text.truncate(15_000)

      parts.join("\n")
    end

    def call_claude(system_prompt, user_content)
      if cli_available?
        call_claude_cli(system_prompt, user_content)
      else
        call_claude_api(system_prompt, user_content)
      end
    end

    def cli_available?
      return @cli_available if defined?(@cli_available)
      @cli_available = claude_path.present?
    end

    def claude_path
      @claude_path ||= [
        "/opt/homebrew/bin/claude",
        "#{ENV['HOME']}/.claude/local/claude",
        `which claude 2>/dev/null`.strip.presence
      ].compact.find { |p| File.executable?(p.to_s) }
    end

    def call_claude_cli(system_prompt, user_content)
      require "open3"

      prompt = "#{system_prompt}\n\n#{user_content}"

      result_text, status = Open3.capture2(
        claude_path, "-p", prompt,
        "--output-format", "text",
        "--model", "sonnet"
      )

      raise Virality::Error, "Claude CLI failed (exit #{status.exitstatus})" unless status.success?
      raise Virality::Error, "Empty response from Claude CLI" if result_text.blank?

      result_text
    end

    def call_claude_api(system_prompt, user_content)
      api_key = ENV["ANTHROPIC_API_KEY"] || Rails.application.credentials.dig(:anthropic, :api_key)
      raise Virality::Error, "Anthropic API key not configured. Install Claude Code CLI or set ANTHROPIC_API_KEY." if api_key.blank?

      client = Anthropic::Client.new(api_key: api_key)

      response = client.messages.create(
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 2048,
        system: system_prompt,
        messages: [{ role: "user", content: user_content }]
      )

      result_text = if response.respond_to?(:content)
        block = response.content.is_a?(Array) ? response.content.first : response.content
        block.respond_to?(:text) ? block.text : block["text"]
      else
        response.dig("content", 0, "text")
      end

      raise Virality::Error, "Empty response from Claude" if result_text.blank?

      result_text
    end

    def parse_response(raw)
      # Strip markdown code fences if present
      cleaned = raw.strip
      cleaned = cleaned.sub(/\A```(?:json)?\s*\n?/, "").sub(/\n?\s*```\z/, "")

      # Find the JSON object
      start_idx = cleaned.index("{")
      end_idx = cleaned.rindex("}")
      raise Virality::Error, "No JSON object found in response" unless start_idx && end_idx

      json_str = cleaned[start_idx..end_idx]
      parsed = JSON.parse(json_str)

      # Validate structure
      dimensions = parsed["dimensions"]
      raise Virality::Error, "Missing dimensions in response" unless dimensions.is_a?(Hash)

      ViralityAnalysis::DIMENSIONS.each do |dim|
        unless dimensions[dim].is_a?(Hash) && dimensions[dim]["score"].is_a?(Numeric)
          raise Virality::Error, "Missing or invalid dimension: #{dim}"
        end
        dimensions[dim]["score"] = dimensions[dim]["score"].to_i.clamp(0, 100)
      end

      parsed
    rescue JSON::ParserError => e
      raise Virality::Error, "Failed to parse virality analysis: #{e.message}"
    end

    def build_result(parsed)
      dimensions = parsed["dimensions"]

      dimension_scores = {}
      dimension_details = {}

      ViralityAnalysis::DIMENSIONS.each do |dim|
        data = dimensions[dim]
        dimension_scores[dim] = data["score"]
        dimension_details[dim] = {
          "score" => data["score"],
          "summary" => data["summary"].to_s,
          "suggestion" => data["suggestion"].to_s
        }
      end

      overall_score = compute_overall_score(dimension_scores)

      {
        overall_score: overall_score,
        dimension_scores: dimension_scores,
        dimension_details: dimension_details,
        strengths: parsed["strengths"]&.first(3)&.join("\n") || "",
        improvements: parsed["improvements"]&.first(3)&.join("\n") || "",
        overall_assessment: parsed["overall_assessment"].to_s
      }
    end

    def compute_overall_score(dimension_scores)
      weighted_sum = DIMENSION_WEIGHTS.sum do |dim, weight|
        (dimension_scores[dim] || 0) * weight
      end
      weighted_sum.round
    end
  end
end
