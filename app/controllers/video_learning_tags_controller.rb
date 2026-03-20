class VideoLearningTagsController < ApplicationController
  before_action :set_video_learning

  def create
    tag = Tag.find_or_create_by!(name: params[:name].strip.downcase)

    unless @video_learning.tags.include?(tag)
      @video_learning.tags << tag
    end

    redirect_to @video_learning, notice: "Tag added."
  end

  def destroy
    tag = @video_learning.tags.find(params[:id])
    @video_learning.tags.delete(tag)
    redirect_to @video_learning, notice: "Tag removed."
  end

  private

  def set_video_learning
    @video_learning = Current.user.video_learnings.find(params[:video_learning_id])
  end
end
