module Content
  class TemplateRegistry
    Template = Data.define(:key, :name, :description, :platform, :content_format, :prompt_template)

    TEMPLATES = [
      # ---------------------------------------------------------------
      # LINKEDIN TEMPLATES
      # ---------------------------------------------------------------
      Template.new(
        key: "linkedin_lessons_learned",
        name: "Lessons Learned",
        description: "Share key insights and personal takeaways from the source material",
        platform: :linkedin,
        content_format: :post,
        prompt_template: <<~PROMPT
          Write a LinkedIn post sharing the most impactful lessons from the source material.

          Structure:
          1. Open with a hook line that captures a surprising or counterintuitive insight
          2. Share 3-5 key lessons, each as a short paragraph with a bold opening statement
          3. For each lesson, briefly explain WHY it matters and HOW it changes your thinking
          4. Close with a reflective question that invites your audience to share their own experience

          Write in first person as someone who genuinely learned from this content. Be specific — use concrete details from the source material rather than generic statements. Reference the expert(s) ({{expert_names}}) naturally.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "linkedin_expert_spotlight",
        name: "Expert Spotlight",
        description: "Highlight one expert's most compelling ideas and perspectives",
        platform: :linkedin,
        content_format: :post,
        prompt_template: <<~PROMPT
          Write a LinkedIn post spotlighting the expertise and ideas of {{expert_names}}.

          Structure:
          1. Hook: Start with the most striking idea or quote from this expert
          2. Context: Briefly introduce who they are and why their perspective matters
          3. Key Ideas: Highlight 2-3 of their most compelling points with your own commentary on why each resonates
          4. Takeaway: What's the ONE thing your audience should remember?
          5. CTA: Ask your audience if they've encountered this expert's work

          Write as someone genuinely impressed by this expert's thinking. Don't be sycophantic — be specific about what makes their ideas valuable. Use direct references to their actual points from the source material.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "linkedin_framework_breakdown",
        name: "Framework Breakdown",
        description: "Explain a key concept or framework in a clear, actionable way",
        platform: :linkedin,
        content_format: :post,
        prompt_template: <<~PROMPT
          Write a LinkedIn post that breaks down a key framework or concept from the source material into something your audience can immediately apply.

          Structure:
          1. Hook: Name the framework/concept and the problem it solves (e.g., "There's a mental model that changed how I think about X")
          2. The Problem: What common mistake or challenge does this address?
          3. The Framework: Explain it in 3-5 clear steps or components
          4. Application: Give a concrete example of how to use it
          5. CTA: Challenge your audience to try applying it this week

          Pick the most actionable concept from the source material. Make it practical and concrete. Credit {{expert_names}} for the idea.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "linkedin_contrarian_take",
        name: "Contrarian Take",
        description: "Challenge common wisdom using insights from the source material",
        platform: :linkedin,
        content_format: :post,
        prompt_template: <<~PROMPT
          Write a LinkedIn post that challenges a piece of common wisdom, using evidence and insights from the source material.

          Structure:
          1. Hook: State the popular belief, then challenge it (e.g., "Everyone says X. But after studying Y, I think they're wrong.")
          2. The Conventional Wisdom: Briefly describe what most people believe and why
          3. The Counter-Evidence: Present 2-3 points from the source material that challenge this view
          4. The Nuance: Explain when the common wisdom IS right and when it breaks down
          5. Your Updated Take: What should people actually do instead?
          6. CTA: Ask if others have noticed this too

          Be respectful but bold. The goal is to make people think, not to be controversial for its own sake. Ground your argument in specific evidence from {{expert_names}}'s material.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      # ---------------------------------------------------------------
      # TWITTER TEMPLATES
      # ---------------------------------------------------------------
      Template.new(
        key: "twitter_key_takeaways",
        name: "Key Takeaways Thread",
        description: "Distill the most important takeaways into a punchy thread",
        platform: :twitter,
        content_format: :thread,
        prompt_template: <<~PROMPT
          Write a Twitter/X thread sharing the key takeaways from the source material.

          Structure:
          - Tweet 1 (HOOK): A bold statement or question that makes people want to read more. Example format: "I just studied [topic] and here are [N] things that blew my mind:"
          - Tweets 2-8: One takeaway per tweet. Lead each with a strong, standalone statement. Add a brief explanation or example. Each tweet must work on its own but also build momentum in the thread.
          - Final tweet: Summarize the thread in one line + CTA ("Follow me for more breakdowns like this" or "Bookmark this thread for later")

          Rules:
          - Each tweet MUST be under 280 characters
          - Number each tweet: 1/, 2/, 3/, etc.
          - Use line breaks within tweets for emphasis
          - Make every word count — cut ruthlessly
          - Reference {{expert_names}} in the first or second tweet

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "twitter_concept_explainer",
        name: "Concept Explainer Thread",
        description: "Break down a complex concept into simple, tweet-sized pieces",
        platform: :twitter,
        content_format: :thread,
        prompt_template: <<~PROMPT
          Write a Twitter/X thread that explains a key concept from the source material in simple terms.

          Structure:
          - Tweet 1 (HOOK): Name the concept and why understanding it is a superpower. Example: "Most people don't understand [concept]. Here's a 2-minute explainer that will change how you think about [topic]:"
          - Tweet 2: The simple definition — explain it like you would to a smart 12-year-old
          - Tweets 3-5: Build up the explanation layer by layer. Use analogies, examples, or "imagine this" scenarios
          - Tweet 6-7: Why it matters in practice — real-world application
          - Tweet 8: Common mistakes or misconceptions about this concept
          - Final tweet: One-line summary + CTA

          Rules:
          - Each tweet MUST be under 280 characters
          - Number each tweet: 1/, 2/, 3/, etc.
          - Use analogies — they're gold on Twitter
          - Credit {{expert_names}} for the explanation

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "twitter_quote_insight",
        name: "Quote + Insight Thread",
        description: "Pair memorable quotes or statements with your own analysis",
        platform: :twitter,
        content_format: :thread,
        prompt_template: <<~PROMPT
          Write a Twitter/X thread that pairs memorable ideas or statements from the source material with sharp analysis.

          Structure:
          - Tweet 1 (HOOK): The most striking quote or idea, framed as: "[Expert] said something that stopped me in my tracks:"
          - For each pair (3-5 pairs):
            - Odd tweet: The quote, paraphrased idea, or key statement (attributed to {{expert_names}})
            - Even tweet: Your analysis — why this matters, what most people miss, or how to apply it
          - Final tweet: The thread's key message in one sentence + CTA

          Rules:
          - Each tweet MUST be under 280 characters
          - Number each tweet: 1/, 2/, 3/, etc.
          - Don't just repeat what was said — add genuine insight
          - Paraphrase rather than fabricating direct quotes unless the source material includes exact wording

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      # ---------------------------------------------------------------
      # YOUTUBE SCRIPT TEMPLATES
      # ---------------------------------------------------------------
      Template.new(
        key: "youtube_summary_script",
        name: "Summary Video Script",
        description: "A video script summarizing the key points from the source material",
        platform: :youtube_script,
        content_format: :script,
        prompt_template: <<~PROMPT
          Write a YouTube video script that summarizes the most important insights from the source material.

          Structure:
          [HOOK - 0:00] (15 seconds)
          Open with a question or surprising fact that immediately communicates value. Example: "What if everything you thought about [topic] was wrong?"

          [INTRO - 0:15] (30 seconds)
          Brief intro: What you'll cover, why it matters, and what viewers will walk away with. Mention this is based on insights from {{expert_names}}.

          [SECTION 1 - 0:45] Title: [Key Point 1]
          Explain the first major insight. Use a story, example, or analogy to make it stick.
          [B-ROLL: relevant visual suggestion]

          [SECTION 2 - 3:00] Title: [Key Point 2]
          Second major insight with practical application.
          [B-ROLL: relevant visual suggestion]

          [SECTION 3 - 5:00] Title: [Key Point 3]
          Third insight — ideally the most surprising or actionable one.

          [MID-ROLL CTA - 6:30]
          "If you're finding this useful, hit that subscribe button — I break down expert insights like this every week."

          [CONCLUSION - 7:00]
          Recap the 3 key points in one sentence each. End with the ONE thing viewers should do today.

          [OUTRO CTA - 7:30]
          "Drop a comment: which of these insights surprised you most? And check out [related video] for more on this topic."

          Write conversationally — this will be spoken aloud. Use contractions, rhetorical questions, and natural transitions.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "youtube_deep_dive_script",
        name: "Deep Dive Script",
        description: "An in-depth video script exploring a concept thoroughly",
        platform: :youtube_script,
        content_format: :script,
        prompt_template: <<~PROMPT
          Write a YouTube video script that does a deep dive into the most important concept from the source material.

          Structure:
          [HOOK - 0:00] (15 seconds)
          Open with a bold claim about why this concept matters more than people think.

          [INTRO - 0:15] (45 seconds)
          Set up the problem this concept solves. Make viewers feel the pain point. Preview the journey: "By the end of this video, you'll understand [concept] well enough to [concrete outcome]."

          [CONTEXT - 1:00] (2 minutes)
          Background: Where does this concept come from? Why is {{expert_names}}'s perspective unique? What do most people get wrong?
          [B-ROLL: relevant visual suggestion]

          [THE CONCEPT EXPLAINED - 3:00] (4 minutes)
          Break the concept down into its components. Use the "what, why, how" framework:
          - WHAT it is (clear definition)
          - WHY it works (the underlying principle)
          - HOW to use it (step-by-step)
          Include analogies and concrete examples from the source material.

          [REAL-WORLD APPLICATION - 7:00] (3 minutes)
          Show 2-3 specific scenarios where this concept applies. Make them relatable.

          [COMMON MISTAKES - 10:00] (2 minutes)
          What do people typically get wrong? How to avoid these pitfalls.

          [MID-ROLL CTA]

          [ADVANCED INSIGHTS - 12:00] (2 minutes)
          For viewers who want to go deeper — nuances, edge cases, advanced applications.

          [CONCLUSION - 14:00]
          Summary + the single most important thing to remember.

          [OUTRO CTA]

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "youtube_comparison_script",
        name: "Comparison Script",
        description: "Compare perspectives from multiple experts on the same topic",
        platform: :youtube_script,
        content_format: :script,
        prompt_template: <<~PROMPT
          Write a YouTube video script that compares and contrasts the perspectives of different experts from the source material.

          Structure:
          [HOOK - 0:00]
          "I studied what multiple experts say about [topic], and they don't all agree. Here's what I found."

          [INTRO - 0:15]
          Set up the topic and introduce the experts ({{expert_names}}). Explain why comparing perspectives is valuable.

          [EXPERT PERSPECTIVES]
          For each expert/video source:
          - Their core argument or unique angle
          - Their strongest point
          - Where they differ from others

          [THE SYNTHESIS]
          Where do experts agree? Where do they diverge? What pattern emerges when you look at all perspectives together?

          [YOUR TAKE]
          Based on analyzing all sources, what's the most complete picture? What should viewers actually take away?

          [CONCLUSION + CTA]

          Write as a curious analyst who has done the research. Be fair to all perspectives. Help viewers think critically rather than just picking a side.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      # ---------------------------------------------------------------
      # BLOG TEMPLATES
      # ---------------------------------------------------------------
      Template.new(
        key: "blog_comprehensive_guide",
        name: "Comprehensive Guide",
        description: "A thorough, well-structured article covering the topic in depth",
        platform: :blog,
        content_format: :article,
        prompt_template: <<~PROMPT
          Write a comprehensive blog article based on the source material.

          Structure (in Markdown):
          # [Compelling, SEO-friendly title]

          **Introduction** (2-3 paragraphs)
          - Hook: Start with a problem, question, or surprising fact
          - Context: Why this topic matters right now
          - Preview: What the reader will learn

          ## [Section 1: Core Concept/Problem]
          Deep explanation of the main idea. Include context from {{expert_names}}.

          ## [Section 2: Key Insights]
          Break down the most important points. Use subheadings (###) for each major insight. Include examples and practical applications.

          ## [Section 3: How to Apply This]
          Actionable steps the reader can take. Be specific and practical.

          ## [Section 4: Common Pitfalls / What to Watch Out For]
          Address misconceptions or common mistakes.

          ## Key Takeaways
          Bulleted list of 5-7 main points.

          ## Conclusion
          Tie everything together. Restate the main value. End with a forward-looking statement or call-to-action.

          Make it genuinely useful — readers should feel like they've learned something concrete they can apply. Reference the source experts naturally throughout. Use bold for key terms and include relevant examples.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "blog_listicle",
        name: "Listicle",
        description: "An engaging 'N things I learned' style article",
        platform: :blog,
        content_format: :article,
        prompt_template: <<~PROMPT
          Write a listicle-style blog article based on the source material.

          Structure (in Markdown):
          # [N] Things I Learned About [Topic] (from {{expert_names}})

          **Introduction** (2-3 paragraphs)
          Brief context: what you studied, why it matters, and what surprised you.

          For each item (aim for 7-12 items):
          ## [N]. [Catchy one-line summary of the learning]
          2-3 paragraphs explaining:
          - The insight itself
          - Why it's surprising or important
          - How to apply it

          ## The Bottom Line
          What's the overarching theme across all these learnings? What should the reader do with this information?

          Rules:
          - Make each item standalone but build a narrative arc across the list
          - Start with a strong item, put the BEST item last
          - Mix practical tips with mindset shifts
          - Be specific — use concrete details from the source material
          - Write in first person

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "blog_expert_roundup",
        name: "Expert Roundup",
        description: "Synthesize wisdom from multiple expert sources into a single article",
        platform: :blog,
        content_format: :article,
        prompt_template: <<~PROMPT
          Write an expert roundup blog article synthesizing insights from the source material.

          Structure (in Markdown):
          # What [N] Experts Taught Me About [Topic]

          **Introduction**
          Set the scene: You've been studying what leading voices ({{expert_names}}) have to say about this topic. Here's what you found.

          ## The Big Picture
          What's the overarching narrative? What theme connects all these expert perspectives?

          ## Expert Insights
          For each expert/source:
          ### [Expert Name]: [Their Key Contribution in One Phrase]
          - Their background/credibility (1 sentence)
          - Their core argument or unique perspective (2-3 paragraphs)
          - The most actionable takeaway from their work

          ## Where They Agree
          Common ground across all sources.

          ## Where They Diverge
          Interesting disagreements or different angles.

          ## What This Means for You
          Practical synthesis: what should the reader actually do with all this expert knowledge?

          ## Final Thoughts
          Your personal take on what you learned from studying all these perspectives.

          Write as a thoughtful curator — add value through synthesis, not just summarization.

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      # ---------------------------------------------------------------
      # NEWSLETTER TEMPLATES
      # ---------------------------------------------------------------
      Template.new(
        key: "newsletter_weekly_digest",
        name: "Weekly Digest",
        description: "A curated weekly roundup of the best insights",
        platform: :newsletter,
        content_format: :article,
        prompt_template: <<~PROMPT
          Write a newsletter issue that curates the best insights from the source material into a weekly digest format.

          Structure:
          **Subject line suggestion:** [Compelling subject line under 50 chars]

          ---

          Hey there,

          [Personal 2-3 sentence opening that connects a real-world observation to this week's theme]

          ## TL;DR
          - [Bullet 1: Key insight in one sentence]
          - [Bullet 2: Key insight in one sentence]
          - [Bullet 3: Key insight in one sentence]

          ## This Week's Big Idea
          [2-3 paragraphs on the most important insight from the source material. Reference {{expert_names}} naturally.]

          ## Quick Hits
          [3-5 shorter insights, each 2-3 sentences. Format as a bulleted list with bold lead-ins.]

          ## One Thing to Try This Week
          [A specific, actionable challenge or experiment based on what you learned. Make it concrete: "Next time you [situation], try [specific action]"]

          ## What I'm Thinking About
          [A thought-provoking question or observation that invites reader replies]

          Until next time,
          [Sign-off]

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "newsletter_deep_dive",
        name: "Deep Dive Edition",
        description: "A focused deep dive into one major topic or concept",
        platform: :newsletter,
        content_format: :article,
        prompt_template: <<~PROMPT
          Write a newsletter issue that does a focused deep dive into the most important concept from the source material.

          Structure:
          **Subject line suggestion:** [Compelling subject line under 50 chars]

          ---

          Hey there,

          [Personal anecdote or observation that naturally leads into today's topic — 3-4 sentences]

          ## TL;DR
          [3-4 bullet points summarizing the key takeaways for skimmers]

          ## The Concept: [Name]
          [Explain the concept clearly. Why does it matter? What problem does it solve? Reference {{expert_names}}'s explanation.]

          ## Why This Matters
          [2-3 paragraphs connecting this concept to your reader's real-world challenges. Use "you" language.]

          ## How to Apply It
          [Step-by-step or scenario-based explanation of how to put this into practice. Be concrete.]

          ## The Nuance Most People Miss
          [What's the subtle but important detail that separates surface-level understanding from deep understanding?]

          ## My Take
          [Your honest reflection on this concept. What convinced you? What are you still unsure about?]

          Reply and let me know: [Specific question inviting a response]

          [Warm sign-off]

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      ),

      Template.new(
        key: "newsletter_quick_insights",
        name: "Quick Insights",
        description: "A short, punchy issue with rapid-fire takeaways",
        platform: :newsletter,
        content_format: :article,
        prompt_template: <<~PROMPT
          Write a short, punchy newsletter issue that delivers maximum value in minimum time.

          Structure:
          **Subject line suggestion:** [Short, curiosity-driven subject line]

          ---

          Hey there,

          [1-2 sentence opening — get straight to the point. "No preamble today — here are the sharpest insights I came across this week."]

          ## 5 Insights in 5 Minutes

          **1. [Insight title]**
          [2-3 sentences max. Make it punchy and immediately useful.]

          **2. [Insight title]**
          [2-3 sentences max.]

          **3. [Insight title]**
          [2-3 sentences max.]

          **4. [Insight title]**
          [2-3 sentences max.]

          **5. [Insight title]**
          [2-3 sentences max.]

          ## The One-Liner
          [The single most memorable takeaway from all sources, distilled to one powerful sentence. Attribute to {{expert_names}} if applicable.]

          ## Your Move
          [One specific action the reader can take today. Keep it to 1-2 sentences.]

          See you next time,
          [Sign-off]

          Topic: {{topic}}

          {{platform_guidelines}}
        PROMPT
      )
    ].freeze

    def self.all
      TEMPLATES
    end

    def self.for_platform(platform)
      TEMPLATES.select { |t| t.platform == platform.to_sym }
    end

    def self.for_platform_and_format(platform, content_format)
      TEMPLATES.select do |t|
        t.platform == platform.to_sym && t.content_format == content_format.to_sym
      end
    end

    def self.find(key)
      TEMPLATES.find { |t| t.key == key.to_s }
    end

    def self.find!(key)
      find(key) || raise(Content::GenerationError, "Template not found: #{key}. Available: #{TEMPLATES.map(&:key).join(', ')}")
    end

    def self.default_for(platform, content_format)
      templates = for_platform_and_format(platform, content_format)
      templates.first
    end
  end
end
