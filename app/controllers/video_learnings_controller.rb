class VideoLearningsController < ApplicationController
  include Pagy::Backend

  before_action :set_video_learning, only: [:show, :destroy, :reprocess]

  def index
    scope = Current.user.video_learnings.recent
    scope = scope.by_status(params[:status]) if params[:status].present?
    scope = scope.joins(:tags).where(tags: { name: params[:tag] }) if params[:tag].present?
    @pagy, @video_learnings = pagy(scope, limit: 12)
  end

  def show
  end

  def new
    @video_learning = VideoLearning.new
  end

  def create
    @video_learning = Current.user.video_learnings.new(video_learning_params)

    if @video_learning.save
      ProcessVideoJob.perform_later(@video_learning.id)
      redirect_to @video_learning, notice: "Video submitted for processing!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @video_learning.destroy
    redirect_to video_learnings_path, notice: "Video learning deleted."
  end

  def search
    if params[:q].present?
      scope = Current.user.video_learnings.search(params[:q])
      @pagy, @video_learnings = pagy(scope, limit: 12)
    else
      @video_learnings = []
    end
  end

  def reprocess
    @video_learning.update!(status: :pending, processing_progress: 0, error_message: nil)
    @video_learning.frames.destroy_all
    ProcessVideoJob.perform_later(@video_learning.id)
    redirect_to @video_learning, notice: "Video resubmitted for processing!"
  end

  private

  def set_video_learning
    @video_learning = Current.user.video_learnings.find(params[:id])
  end

  def video_learning_params
    params.require(:video_learning).permit(:youtube_url)
  end
end
