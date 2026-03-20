module Embeddings
  class VideoLearningEmbedder
    def initialize(video_learning)
      @vl = video_learning
    end

    def embeddable_text
      parts = []
      parts << "Title: #{@vl.title}" if @vl.title.present?
      parts << "Channel: #{@vl.channel_name}" if @vl.channel_name.present?
      parts << "Summary: #{@vl.summary}" if @vl.summary.present?

      if @vl.key_takeaways.present?
        parts << "Key Takeaways: #{@vl.key_takeaways.join('. ')}"
      end

      if @vl.concepts.present?
        concept_text = @vl.concepts.map { |c| "#{c['name']}: #{c['description']}" }.join(". ")
        parts << "Concepts: #{concept_text}"
      end

      if @vl.detailed_notes.present?
        parts << "Notes: #{@vl.detailed_notes.truncate(5000)}"
      end

      parts.join("\n\n")
    end
  end
end
