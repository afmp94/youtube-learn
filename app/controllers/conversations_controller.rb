class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :destroy, :ask]

  def index
    @conversations = Current.user.conversations.recent.includes(:messages)
  end

  def show
    @messages = @conversation.messages.order(created_at: :asc)
  end

  def new
    @conversation = Conversation.new
    @suggestions = generate_suggestions
  end

  def create
    @conversation = Current.user.conversations.new(title: conversation_title)

    if @conversation.save
      if params[:message].present?
        # Save the user message and enqueue AI response
        user_msg = @conversation.messages.create!(role: :user, content: params[:message].strip)
        ChatResponseJob.perform_later(@conversation.id, params[:message].strip)
      end
      redirect_to @conversation
    else
      @suggestions = generate_suggestions
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation.destroy
    redirect_to conversations_path, notice: "Conversation deleted."
  end

  def ask
    message = params[:message].to_s.strip
    if message.blank?
      redirect_to @conversation, alert: "Please enter a message."
      return
    end

    # Create the user message immediately for display
    user_msg = @conversation.messages.create!(role: :user, content: message)
    @conversation.touch

    # Enqueue the AI response job
    ChatResponseJob.perform_later(@conversation.id, message)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.append("messages", partial: "conversations/message", locals: { message: user_msg }),
          turbo_stream.append("messages", partial: "conversations/typing_indicator"),
          turbo_stream.replace("chat_input_form", partial: "conversations/input_form", locals: { conversation: @conversation })
        ]
      }
      format.html { redirect_to @conversation }
    end
  end

  private

  def set_conversation
    @conversation = Current.user.conversations.find(params[:id])
  end

  def conversation_title
    if params[:message].present?
      params[:message].to_s.truncate(60)
    else
      params.dig(:conversation, :title).presence || "New Chat"
    end
  end

  def generate_suggestions
    suggestions = []
    user_videos = Current.user.video_learnings.completed

    # Suggestion based on top tag
    top_tag = Tag.joins(:video_learning_tags)
      .where(video_learning_tags: { video_learning_id: user_videos.select(:id) })
      .group(:id)
      .order(Arel.sql("COUNT(*) DESC"))
      .first
    if top_tag
      suggestions << "What have I learned about #{top_tag.name}?"
    end

    # Suggestion based on a channel
    top_channel = user_videos.where.not(channel_name: [nil, ""])
      .group(:channel_name)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(1)
      .pick(:channel_name)
    if top_channel
      suggestions << "Summarize the key ideas from #{top_channel}"
    end

    # Suggestion based on concepts
    video_with_concepts = user_videos.where.not(concepts: nil).order(created_at: :desc).first
    if video_with_concepts && video_with_concepts.concepts.present?
      concept_name = video_with_concepts.concepts.first&.dig("name")
      suggestions << "Compare perspectives on #{concept_name}" if concept_name
    end

    # Always include a general suggestion
    suggestions << "What are the most actionable takeaways across all my videos?"

    suggestions.first(4)
  end
end
