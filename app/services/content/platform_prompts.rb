module Content
  class PlatformPrompts
    GUIDELINES = {
      linkedin: <<~GUIDE,
        LINKEDIN WRITING GUIDELINES:
        - Professional but approachable tone; write as a thought leader sharing genuine insights
        - Ideal length: 1,300 characters (max 3,000 characters)
        - Hook in the FIRST LINE is critical — it appears before "...see more" and determines if people read on
        - Use short paragraphs (1-2 sentences each) with line breaks between them for readability
        - Use bullet points or numbered lists for key points
        - Use emoji sparingly (1-3 max) and only where they add meaning
        - End with a question, call-to-action, or thought-provoking statement to drive engagement
        - Include 3-5 relevant hashtags at the end
        - Write in first person ("I learned...", "Here's what surprised me...")
        - Avoid clickbait; be authentic and substantive
        - If referencing a video or expert, credit them naturally ("I was watching X's take on...")
      GUIDE

      twitter: <<~GUIDE,
        TWITTER/X THREAD WRITING GUIDELINES:
        - Each tweet must be 280 characters or fewer
        - First tweet is the HOOK — it must stop the scroll. Use a bold claim, surprising stat, or provocative question
        - Number each tweet in a thread (1/, 2/, etc.)
        - Keep each tweet as a self-contained idea that also flows into the next
        - Use punchy, direct language — cut every unnecessary word
        - End the thread with a summary tweet and call-to-action ("Follow for more", "Bookmark this thread")
        - Use line breaks within tweets for emphasis
        - Thread length: 5-12 tweets is the sweet spot
        - No hashtags mid-tweet; optionally add 1-2 at the end of the last tweet
        - Use "you" language to speak directly to the reader
      GUIDE

      youtube_script: <<~GUIDE,
        YOUTUBE SCRIPT WRITING GUIDELINES:
        - Open with a HOOK (first 15 seconds) — pose a question, share a surprising fact, or preview the value
        - Follow with a brief intro: who you are, what this video covers, and why it matters
        - Structure the body into clear, labeled sections with smooth transitions
        - Write conversationally — this will be spoken aloud. Use contractions, rhetorical questions, asides
        - Include [TIMESTAMP] markers for each major section
        - Add [B-ROLL] or [VISUAL] cues where supporting imagery would help
        - Include a mid-video CTA ("If you're finding this useful, hit subscribe")
        - End with a strong conclusion that summarizes key points
        - Final CTA: like, subscribe, comment prompt (ask a specific question)
        - Target length: 1,000-2,500 words depending on depth
        - Pace: mix short punchy sentences with longer explanatory ones
      GUIDE

      blog: <<~GUIDE,
        BLOG ARTICLE WRITING GUIDELINES:
        - SEO-friendly: include relevant keywords naturally in the title, headers, and first paragraph
        - Use a compelling title that promises clear value (How to..., N Things..., The Complete Guide to...)
        - Start with a hook paragraph that establishes the problem or opportunity
        - Use H2 and H3 headers to break content into scannable sections
        - Target 800-2,000 words depending on topic depth
        - Include an introduction (problem/context), body (main content), and conclusion (summary/next steps)
        - Use bullet points, numbered lists, and bold text for key terms
        - Write in an authoritative but accessible tone
        - Include practical examples, actionable tips, or real-world applications
        - End with a clear takeaway or call-to-action
        - Format output as clean Markdown
      GUIDE

      newsletter: <<~GUIDE,
        NEWSLETTER WRITING GUIDELINES:
        - Personal, conversational tone — write as if emailing a smart friend
        - Start with a brief personal anecdote or hook that connects to the main theme
        - ONE main theme per issue, with supporting points
        - Make it scannable: use headers, bold key phrases, bullet points
        - Keep sections short (2-4 paragraphs each)
        - Structure: Greeting/Hook -> Main Insight -> Supporting Points -> Quick Wins/Tips -> Sign-off
        - Include a "TL;DR" or key takeaway box near the top for skimmers
        - Reference sources naturally ("I came across this in a video by...")
        - End with a question or prompt that invites replies
        - Total length: 500-1,200 words — respect your reader's inbox
        - Use a consistent, warm sign-off
      GUIDE
    }.freeze

    def self.for(platform)
      key = platform.to_sym
      GUIDELINES.fetch(key) do
        raise Content::GenerationError, "Unknown platform: #{platform}. Valid platforms: #{GUIDELINES.keys.join(', ')}"
      end
    end
  end
end
