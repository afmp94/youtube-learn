class ProjectsController < ApplicationController
  include Pagy::Backend

  before_action :require_authentication
  before_action :set_project, only: [:show, :edit, :update, :destroy, :add_video, :remove_video, :archive, :unarchive]

  def index
    @projects = Current.user.projects.active.recent
  end

  def show
    @knowledge_entries = @project.knowledge_entries.recent.limit(20)
    @video_learnings = @project.video_learnings
                                .includes(:tags)
                                .order("project_video_learnings.created_at DESC")
    @content_pieces = @project.content_pieces.recent.limit(10)
    @available_videos = Current.user.video_learnings
                                    .completed
                                    .where.not(id: @project.video_learning_ids)
                                    .recent
                                    .limit(50)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Current.user.projects.new(project_params)
    if @project.save
      redirect_to @project, notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  def add_video
    video = Current.user.video_learnings.find(params[:video_learning_id])
    unless @project.video_learnings.include?(video)
      @project.project_video_learnings.create!(video_learning: video)
    end
    reload_show_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("project_videos", partial: "projects/video_grid", locals: { video_learnings: @video_learnings, project: @project }),
          turbo_stream.replace("add_video_form", partial: "projects/add_video_form", locals: { project: @project, available_videos: @available_videos }),
          turbo_stream.replace("project_stats", partial: "projects/stats", locals: { project: @project })
        ]
      end
      format.html { redirect_to @project, notice: "Video added." }
    end
  end

  def remove_video
    video = Current.user.video_learnings.find(params[:video_learning_id])
    @project.project_video_learnings.find_by(video_learning: video)&.destroy
    reload_show_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("project_videos", partial: "projects/video_grid", locals: { video_learnings: @video_learnings, project: @project }),
          turbo_stream.replace("add_video_form", partial: "projects/add_video_form", locals: { project: @project, available_videos: @available_videos }),
          turbo_stream.replace("project_stats", partial: "projects/stats", locals: { project: @project })
        ]
      end
      format.html { redirect_to @project, notice: "Video removed." }
    end
  end

  def archive
    @project.archived!
    redirect_to projects_path, notice: "Project archived."
  end

  def unarchive
    @project.active!
    redirect_to @project, notice: "Project reactivated."
  end

  private

  def set_project
    @project = Current.user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :brief, :color)
  end

  def reload_show_data
    @video_learnings = @project.video_learnings.reload.includes(:tags)
                                .order("project_video_learnings.created_at DESC")
    @available_videos = Current.user.video_learnings
                                    .completed
                                    .where.not(id: @project.video_learning_ids)
                                    .recent
                                    .limit(50)
  end
end
