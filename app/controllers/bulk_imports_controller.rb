class BulkImportsController < ApplicationController
  def index
    @bulk_imports = Current.user.bulk_imports.recent
  end

  def new
    @bulk_import = BulkImport.new
  end

  def create
    @bulk_import = Current.user.bulk_imports.new(bulk_import_params)

    if @bulk_import.save
      BulkImportJob.perform_later(@bulk_import.id)
      redirect_to @bulk_import, notice: "Import started! We're discovering videos in the playlist."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @bulk_import = Current.user.bulk_imports.find(params[:id])
    @video_learnings = Current.user.video_learnings
                            .where(bulk_import: @bulk_import)
                            .order(created_at: :desc)
  end

  private

  def bulk_import_params
    params.require(:bulk_import).permit(:source_url, :import_type)
  end
end
