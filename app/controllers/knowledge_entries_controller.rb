class KnowledgeEntriesController < ApplicationController
  before_action :set_project
  before_action :set_knowledge_entry, only: [:show, :edit, :update, :destroy]

  def new
    @knowledge_entry = @project.knowledge_entries.new(entry_type: params[:type] || :note)
  end

  def create
    @knowledge_entry = @project.knowledge_entries.new(knowledge_entry_params)
    @knowledge_entry.user = Current.user

    if @knowledge_entry.save
      redirect_to project_path(@project), notice: "#{@knowledge_entry.entry_type.titleize} added to knowledge base."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def update
    if @knowledge_entry.update(knowledge_entry_params)
      redirect_to project_knowledge_entry_path(@project, @knowledge_entry), notice: "Entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @knowledge_entry.destroy
    redirect_to project_path(@project), notice: "Entry deleted."
  end

  private

  def set_project
    @project = Current.user.projects.find(params[:project_id])
  end

  def set_knowledge_entry
    @knowledge_entry = @project.knowledge_entries.find(params[:id])
  end

  def knowledge_entry_params
    params.require(:knowledge_entry).permit(:entry_type, :title, :body, :source_url, :summary, :file)
  end
end
