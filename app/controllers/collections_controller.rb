class CollectionsController < ApplicationController
  include Pagy::Backend

  before_action :require_authentication
  before_action :set_collection, only: [:show, :edit, :update, :destroy, :add_video, :remove_video]

  def index
    @pagy, @collections = pagy(Current.user.collections.recent, limit: 12)
  end

  def show
    @video_learnings = @collection.video_learnings
                                  .includes(:tags)
                                  .order("collection_video_learnings.position ASC, collection_video_learnings.created_at DESC")
    @available_videos = Current.user.video_learnings
                                    .completed
                                    .where.not(id: @collection.video_learning_ids)
                                    .recent
    @content_pieces = @collection.content_pieces.recent
  end

  def new
    @collection = Collection.new
  end

  def create
    @collection = Current.user.collections.new(collection_params)

    if @collection.save
      redirect_to @collection, notice: "Collection created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      redirect_to @collection, notice: "Collection updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy
    redirect_to collections_path, notice: "Collection deleted."
  end

  def add_video
    video_learning = Current.user.video_learnings.find(params[:video_learning_id])

    unless @collection.video_learnings.include?(video_learning)
      max_position = @collection.collection_video_learnings.maximum(:position) || 0
      @collection.collection_video_learnings.create!(video_learning: video_learning, position: max_position + 1)
    end

    @available_videos = Current.user.video_learnings
                                    .completed
                                    .where.not(id: @collection.video_learning_ids)
                                    .recent

    respond_to do |format|
      format.turbo_stream do
        videos = @collection.video_learnings.includes(:tags)
                             .order("collection_video_learnings.position ASC, collection_video_learnings.created_at DESC")
        render turbo_stream: [
          turbo_stream.replace("collection_videos", partial: "collections/video_grid", locals: { video_learnings: videos, collection: @collection }),
          turbo_stream.replace("add_video_form", partial: "collections/add_video_form", locals: { collection: @collection, available_videos: @available_videos }),
          turbo_stream.replace("collection_stats", partial: "collections/stats", locals: { collection: @collection })
        ]
      end
      format.html { redirect_to @collection, notice: "Video added to collection." }
    end
  end

  def remove_video
    video_learning = Current.user.video_learnings.find(params[:video_learning_id])
    @collection.collection_video_learnings.find_by(video_learning: video_learning)&.destroy

    @available_videos = Current.user.video_learnings
                                    .completed
                                    .where.not(id: @collection.video_learning_ids)
                                    .recent

    respond_to do |format|
      format.turbo_stream do
        videos = @collection.video_learnings.reload.includes(:tags)
                             .order("collection_video_learnings.position ASC, collection_video_learnings.created_at DESC")
        render turbo_stream: [
          turbo_stream.replace("collection_videos", partial: "collections/video_grid", locals: { video_learnings: videos, collection: @collection }),
          turbo_stream.replace("add_video_form", partial: "collections/add_video_form", locals: { collection: @collection, available_videos: @available_videos }),
          turbo_stream.replace("collection_stats", partial: "collections/stats", locals: { collection: @collection })
        ]
      end
      format.html { redirect_to @collection, notice: "Video removed from collection." }
    end
  end

  private

  def set_collection
    @collection = Current.user.collections.find(params[:id])
  end

  def collection_params
    params.require(:collection).permit(:name, :description)
  end
end
