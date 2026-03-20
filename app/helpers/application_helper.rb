module ApplicationHelper
  include Pagy::Frontend

  def render_markdown(text)
    return "" if text.blank?
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: true)
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      no_intra_emphasis: true
    )
    markdown.render(text).html_safe
  end

  def status_label(video_learning)
    case video_learning.status
    when "pending" then "Waiting to start..."
    when "extracting" then "Extracting content..."
    when "analyzing" then "Analyzing with AI..."
    when "completed" then "Complete"
    when "failed" then "Failed"
    end
  end
end
