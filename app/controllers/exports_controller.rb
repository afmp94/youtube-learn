class ExportsController < ApplicationController
  before_action :set_video_learning

  def markdown
    export = Videos::ExportService.new(@video_learning)
    send_data export.to_markdown,
      filename: "#{@video_learning.title&.parameterize || 'video'}-notes.md",
      type: "text/markdown"
  end

  def pdf
    export = Videos::ExportService.new(@video_learning)
    send_data export.to_pdf,
      filename: "#{@video_learning.title&.parameterize || 'video'}-notes.pdf",
      type: "application/pdf"
  end

  private

  def set_video_learning
    @video_learning = Current.user.video_learnings.find(params[:id])
  end
end
