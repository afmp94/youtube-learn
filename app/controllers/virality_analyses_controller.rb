class ViralityAnalysesController < ApplicationController
  include Pagy::Backend

  before_action :set_analysis, only: [:show, :destroy]

  def index
    @content_pieces = Current.user.content_pieces.recent.limit(50)
    @video_learnings = Current.user.video_learnings.where(status: :completed).order(created_at: :desc).limit(50)
    @pagy, @recent_analyses = pagy(Current.user.virality_analyses.recent, limit: 10)
  end

  def show
  end

  def create
    analysis = Current.user.virality_analyses.new(
      input_type: params[:input_type] || "free_text",
      target_platform: params[:target_platform].presence,
      status: :pending
    )

    case params[:input_type]
    when "content_piece"
      if params[:content_piece_id].present?
        cp = Current.user.content_pieces.find(params[:content_piece_id])
        analysis.analyzable = cp
        analysis.input_text = [cp.title, cp.body].compact.join("\n\n")
        analysis.title = cp.title.presence || "#{cp.platform_label} content"
        analysis.target_platform ||= cp.platform
      else
        redirect_to virality_analyses_path, alert: "Please select a content piece." and return
      end
    when "video_learning"
      if params[:video_learning_id].present?
        vl = Current.user.video_learnings.find(params[:video_learning_id])
        analysis.analyzable = vl
        analysis.input_text = compile_video_input(vl)
        analysis.title = vl.title.presence || "Video analysis"
      else
        redirect_to virality_analyses_path, alert: "Please select a video." and return
      end
    when "strategy"
      analysis.input_text = params[:input_text]
      analysis.title = params[:input_text]&.truncate(60)
    else
      analysis.input_text = params[:input_text]
      analysis.title = params[:input_text]&.truncate(60)
    end

    if analysis.save
      @analysis = analysis
      ViralityAnalysisJob.perform_later(analysis.id)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to virality_analysis_path(@analysis), notice: "Analyzing virality..." }
      end
    else
      redirect_to virality_analyses_path, alert: "Could not start analysis: #{analysis.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @analysis.destroy
    redirect_to virality_analyses_path, notice: "Analysis deleted."
  end

  private

  def set_analysis
    @analysis = Current.user.virality_analyses.find(params[:id])
  end

  def compile_video_input(vl)
    parts = []
    parts << "Title: #{vl.title}" if vl.title.present?
    parts << "Channel: #{vl.channel_name}" if vl.channel_name.present?
    parts << "Summary: #{vl.summary}" if vl.summary.present?
    if vl.key_takeaways.present?
      takeaways = vl.key_takeaways.is_a?(Array) ? vl.key_takeaways : [vl.key_takeaways]
      parts << "Key Takeaways:\n#{takeaways.first(10).map { |t| "- #{t}" }.join("\n")}"
    end
    if vl.concepts.present?
      concepts = vl.concepts.is_a?(Array) ? vl.concepts : [vl.concepts]
      concept_names = concepts.first(10).map { |c| c.is_a?(Hash) ? c["name"] : c.to_s }
      parts << "Concepts: #{concept_names.join(', ')}"
    end
    if vl.detailed_notes.present?
      parts << "Detailed Notes:\n#{vl.detailed_notes.truncate(5000)}"
    end
    parts.join("\n\n")
  end
end
