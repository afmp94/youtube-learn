module Videos
  class ExportService
    def initialize(video_learning)
      @vl = video_learning
    end

    def to_markdown
      parts = []
      parts << "# #{@vl.title}"
      parts << ""
      parts << "**Channel:** #{@vl.channel_name}" if @vl.channel_name
      parts << "**Duration:** #{@vl.formatted_duration}" if @vl.duration_seconds
      parts << "**Difficulty:** #{@vl.difficulty_level&.capitalize}" if @vl.difficulty_level
      parts << "**URL:** #{@vl.youtube_url}"
      parts << ""

      if @vl.summary.present?
        parts << "## Summary"
        parts << ""
        parts << @vl.summary
        parts << ""
      end

      if @vl.key_takeaways.present?
        parts << "## Key Takeaways"
        parts << ""
        @vl.key_takeaways.each { |t| parts << "- #{t}" }
        parts << ""
      end

      if @vl.concepts.present?
        parts << "## Concepts"
        parts << ""
        @vl.concepts.each do |c|
          parts << "### #{c['name']}"
          parts << c["description"] if c["description"]
          parts << ""
        end
      end

      if @vl.detailed_notes.present?
        parts << "## Detailed Notes"
        parts << ""
        parts << @vl.detailed_notes
        parts << ""
      end

      if @vl.tags.any?
        parts << "---"
        parts << "**Tags:** #{@vl.tag_list.join(', ')}"
      end

      parts.join("\n")
    end

    def to_pdf
      pdf = Prawn::Document.new(page_size: "A4", margin: 40)

      pdf.font_size(24) { pdf.text @vl.title || "Untitled", style: :bold }
      pdf.move_down 10

      meta = []
      meta << "Channel: #{@vl.channel_name}" if @vl.channel_name
      meta << "Duration: #{@vl.formatted_duration}" if @vl.duration_seconds
      meta << "Difficulty: #{@vl.difficulty_level&.capitalize}" if @vl.difficulty_level
      pdf.font_size(10) { pdf.text meta.join("  |  "), color: "666666" }
      pdf.move_down 20

      if @vl.summary.present?
        pdf.font_size(16) { pdf.text "Summary", style: :bold }
        pdf.move_down 8
        pdf.text @vl.summary
        pdf.move_down 15
      end

      if @vl.key_takeaways.present?
        pdf.font_size(16) { pdf.text "Key Takeaways", style: :bold }
        pdf.move_down 8
        @vl.key_takeaways.each do |takeaway|
          pdf.text "\u2022 #{takeaway}", indent_paragraphs: 10
          pdf.move_down 4
        end
        pdf.move_down 15
      end

      if @vl.concepts.present?
        pdf.font_size(16) { pdf.text "Concepts", style: :bold }
        pdf.move_down 8
        @vl.concepts.each do |concept|
          pdf.font_size(12) { pdf.text concept["name"], style: :bold }
          pdf.text concept["description"] if concept["description"]
          pdf.move_down 8
        end
        pdf.move_down 15
      end

      if @vl.detailed_notes.present?
        pdf.font_size(16) { pdf.text "Detailed Notes", style: :bold }
        pdf.move_down 8
        pdf.text @vl.detailed_notes
      end

      pdf.render
    end
  end
end
