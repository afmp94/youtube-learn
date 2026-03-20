class ContentPiecesController < ApplicationController
  include Pagy::Backend

  before_action :set_content_piece, only: [:show, :edit, :update, :destroy, :regenerate, :update_status]

  def index
    scope = Current.user.content_pieces.recent
    scope = scope.by_platform(params[:platform]) if params[:platform].present?
    scope = scope.by_status(params[:status]) if params[:status].present?
    @pagy, @content_pieces = pagy(scope, limit: 12)
  end

  def show
  end

  def new
    @video_count = Current.user.video_learnings.completed.count
    @top_channels = Current.user.channels.by_video_count.limit(5).pluck(:name)
    @top_tags = Current.user.video_learnings
      .joins(:tags)
      .select("tags.name")
      .group("tags.name")
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(5)
      .pluck("tags.name")
    @projects = Current.user.projects.active.recent
    @selected_project = Current.user.projects.find_by(id: params[:project_id])
  end

  def create
    @content_piece = Current.user.content_pieces.new(content_piece_params)

    if params[:video_learning_ids].present?
      video_learnings = Current.user.video_learnings.where(id: params[:video_learning_ids])
      @content_piece.video_learnings = video_learnings
    end

    if @content_piece.save
      redirect_to @content_piece, notice: "Content piece created."
    else
      @collections = Current.user.collections.recent
      @video_learnings = Current.user.video_learnings.completed.recent
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @content_piece.update(content_piece_params)
      redirect_to @content_piece, notice: "Content piece updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @content_piece.destroy
    redirect_to content_pieces_path, notice: "Content piece deleted."
  end

  def generate
    prompt = params[:prompt]&.strip

    if prompt.blank?
      redirect_to new_content_piece_path, alert: "Tell me what you want to create!"
      return
    end

    platform = params[:platform].presence || "linkedin"

    SmartGenerateContentJob.perform_later(
      user_id: Current.user.id,
      prompt: prompt,
      platform: platform,
      project_id: params[:project_id].presence&.to_i
    )

    redirect_to content_pieces_path, notice: "Creating your content... this takes a few seconds."
  end

  def regenerate
    GenerateContentJob.perform_later(
      user_id: Current.user.id,
      video_learning_ids: @content_piece.video_learning_ids,
      platform: @content_piece.platform,
      content_format: @content_piece.content_format,
      template_name: @content_piece.template_name
    )

    redirect_to content_pieces_path, notice: "Content is being regenerated..."
  end

  def update_status
    if @content_piece.update(status: params[:status])
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "content_piece_status_#{@content_piece.id}",
            partial: "content_pieces/status_badge",
            locals: { content_piece: @content_piece }
          )
        end
        format.html { redirect_to @content_piece, notice: "Status updated to #{@content_piece.status}." }
      end
    else
      redirect_to @content_piece, alert: "Could not update status."
    end
  end

  private

  def set_content_piece
    @content_piece = Current.user.content_pieces.find(params[:id])
  end

  def content_piece_params
    params.require(:content_piece).permit(:title, :body, :platform, :content_format, :status, :template_name, :collection_id)
  end
end
