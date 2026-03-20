class TagsController < ApplicationController
  include Pagy::Backend

  def index
    @tags = Tag.popular.limit(50)
  end

  def show
    @tag = Tag.find_by!(name: params[:id])
    scope = Current.user.video_learnings.joins(:tags).where(tags: { id: @tag.id }).recent
    @pagy, @video_learnings = pagy(scope, limit: 12)
  end
end
