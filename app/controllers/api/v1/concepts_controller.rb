module Api
  module V1
    class ConceptsController < BaseController
      def index
        videos = current_user.video_learnings.completed.where.not(concepts: nil)
        all_concepts = videos.pluck(:concepts).flatten.compact

        grouped = all_concepts.group_by { |c| c["name"]&.downcase&.strip }

        results = grouped.filter_map do |name, occurrences|
          next if name.blank?
          {
            name: occurrences.first["name"],
            count: occurrences.size,
            descriptions: occurrences.map { |c| c["description"] }.uniq.compact.first(3),
            importance_levels: occurrences.map { |c| c["importance"] }.tally
          }
        end

        min_count = params.fetch(:min_count, 2).to_i
        results = results.select { |c| c[:count] >= min_count }
        results.sort_by! { |c| -c[:count] }

        render json: { concepts: results.first(100), total: results.size }
      end
    end
  end
end
