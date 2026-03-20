module Content
  class KnowledgeCompiler
    MAX_CHARS = 50_000

    def initialize(video_learning_ids: [], collection: nil)
      @video_learning_ids = video_learning_ids
      @collection = collection
    end

    def call
      learnings = fetch_learnings
      raise Content::GenerationError, "No video learnings found" if learnings.empty?

      compiled = compile(learnings)
      truncate_intelligently(compiled)
    end

    def expert_names
      fetch_learnings.filter_map(&:channel_name).uniq
    end

    def topic_summary
      titles = fetch_learnings.map(&:title).compact
      return "various topics" if titles.empty?

      if titles.size == 1
        titles.first
      else
        titles.first(3).join(", ") + (titles.size > 3 ? " and more" : "")
      end
    end

    private

    def fetch_learnings
      @learnings ||= begin
        ids = @video_learning_ids.presence || @collection&.video_learning_ids || []
        VideoLearning.where(id: ids).completed.includes(:tags)
      end
    end

    def compile(learnings)
      sections = []

      sections << "=" * 60
      sections << "SOURCE MATERIAL: #{learnings.size} video(s)"
      sections << "=" * 60

      learnings.each_with_index do |vl, idx|
        sections << ""
        sections << "-" * 40
        sections << "VIDEO #{idx + 1}: #{vl.title}"
        sections << "Channel/Expert: #{vl.channel_name}" if vl.channel_name.present?
        sections << "Difficulty: #{vl.difficulty_level}" if vl.difficulty_level.present?
        sections << "Tags: #{vl.tag_list.join(', ')}" if vl.tags.any?
        sections << "-" * 40

        if vl.summary.present?
          sections << ""
          sections << "SUMMARY:"
          sections << vl.summary
        end

        if vl.key_takeaways.present? && vl.key_takeaways.any?
          sections << ""
          sections << "KEY TAKEAWAYS:"
          vl.key_takeaways.each_with_index do |takeaway, i|
            sections << "  #{i + 1}. #{takeaway}"
          end
        end

        if vl.concepts.present? && vl.concepts.any?
          sections << ""
          sections << "CONCEPTS:"
          vl.concepts.each do |concept|
            name = concept["name"] || concept[:name]
            desc = concept["description"] || concept[:description]
            importance = concept["importance"] || concept[:importance]
            sections << "  - #{name} (#{importance}): #{desc}"
          end
        end

        if vl.detailed_notes.present?
          sections << ""
          sections << "DETAILED NOTES:"
          sections << vl.detailed_notes
        end
      end

      sections.join("\n")
    end

    def truncate_intelligently(text)
      return text if text.length <= MAX_CHARS

      # Prioritize: summaries + takeaways + concepts are kept intact.
      # Truncate detailed_notes sections first by finding them and shortening.
      lines = text.lines
      result = []
      in_notes = false
      notes_budget_per_video = remaining_budget(text, lines)

      notes_chars = 0

      lines.each do |line|
        if line.strip == "DETAILED NOTES:"
          in_notes = true
          notes_chars = 0
          result << line
          next
        end

        if in_notes
          if line.start_with?("-" * 10) || line.strip.start_with?("VIDEO ")
            in_notes = false
            result << line
          elsif notes_chars < notes_budget_per_video
            result << line
            notes_chars += line.length
          elsif notes_chars == notes_budget_per_video
            result << "\n[... detailed notes truncated for length ...]\n"
            notes_chars += 1 # prevent repeated truncation messages
          end
        else
          result << line
        end
      end

      compiled = result.join
      compiled.length > MAX_CHARS ? compiled[0...MAX_CHARS] + "\n[... truncated ...]" : compiled
    end

    def remaining_budget(text, lines)
      # Calculate how much space is used by non-notes content
      non_notes_size = 0
      in_notes = false

      lines.each do |line|
        if line.strip == "DETAILED NOTES:"
          in_notes = true
          non_notes_size += line.length
          next
        end
        if in_notes && (line.start_with?("-" * 10) || line.strip.start_with?("VIDEO "))
          in_notes = false
        end
        non_notes_size += line.length unless in_notes
      end

      notes_sections = lines.count { |l| l.strip == "DETAILED NOTES:" }
      notes_sections = [notes_sections, 1].max

      (MAX_CHARS - non_notes_size) / notes_sections
    end
  end
end
