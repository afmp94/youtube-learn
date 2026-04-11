class ViralityAnalysisJob < ApplicationJob
  queue_as :default

  def perform(virality_analysis_id)
    analysis = ViralityAnalysis.find(virality_analysis_id)
    analysis.update!(status: :analyzing)
    broadcast_status(analysis, :analyzing)

    # Step 1: Claude AI analysis
    result = Virality::AnalysisService.new(
      user: analysis.user,
      input_text: analysis.input_text,
      input_type: analysis.input_type,
      target_platform: analysis.target_platform,
      analyzable: analysis.analyzable
    ).call

    analysis.update!(
      overall_score: result[:overall_score],
      dimension_scores: result[:dimension_scores],
      dimension_details: result[:dimension_details],
      strengths: result[:strengths],
      improvements: result[:improvements],
      overall_assessment: result[:overall_assessment]
    )

    # Step 2: TRIBE v2 brain analysis (non-blocking)
    run_brain_analysis(analysis)

    analysis.update!(status: :completed)
    broadcast_status(analysis, :completed)
  rescue Virality::Error => e
    analysis&.update!(status: :failed, error_message: e.message)
    broadcast_status(analysis, :failed)
  rescue => e
    Rails.logger.error("ViralityAnalysisJob failed: #{e.class} - #{e.message}")
    analysis&.update!(status: :failed, error_message: "Unexpected error: #{e.message}")
    broadcast_status(analysis, :failed) if analysis
  end

  private

  def run_brain_analysis(analysis)
    analysis.update!(brain_status: :brain_analyzing)

    brain_result = Virality::BrainAnalysisService.new(analysis: analysis).call

    if brain_result[:skipped]
      analysis.update!(brain_status: :brain_skipped)
    else
      analysis.update!(
        brain_status: :brain_completed,
        brain_data: brain_result[:brain_data]
      )
    end
  rescue => e
    Rails.logger.error("TRIBE v2 brain analysis failed: #{e.class} - #{e.message}")
    analysis.update!(brain_status: :brain_failed, brain_error_message: e.message.truncate(500))
  end

  def broadcast_status(analysis, status)
    return unless analysis&.user_id

    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{analysis.user_id}_virality",
      target: "virality_result",
      partial: "virality_analyses/result",
      locals: { analysis: analysis, status: status }
    )
  end
end
