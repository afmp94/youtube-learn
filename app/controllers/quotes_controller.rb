class QuotesController < ApplicationController
  include Pagy::Backend

  def index
    scope = user_quotes.includes(video_learning: :channel)

    if params[:speaker].present?
      scope = scope.by_speaker(params[:speaker])
    end

    scope = scope.recent
    @pagy, @quotes = pagy(scope, limit: 24)

    @speakers = user_quotes.where.not(speaker: [nil, ""])
      .distinct.pluck(:speaker).sort
  end

  def search
    if params[:q].present?
      scope = user_quotes.includes(video_learning: :channel)
        .where("quotes.text ILIKE ?", "%#{params[:q]}%")
        .recent

      @pagy, @quotes = pagy(scope, limit: 24)
    else
      @quotes = Quote.none
      @pagy = nil
    end

    @speakers = user_quotes.where.not(speaker: [nil, ""])
      .distinct.pluck(:speaker).sort

    render :index
  end

  private

  def user_quotes
    Quote.joins(:video_learning)
      .where(video_learnings: { user_id: Current.user.id })
  end
end
