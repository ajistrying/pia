module ApplicationHelper
  def workspace_task_completed?(workspace_id, task_type)
    # Try cache first
    begin
      cache_result = Rails.cache.read("workspace_#{workspace_id}_task_#{task_type}")
      return true if cache_result.present?
    rescue => e
      Rails.logger.warn "Cache read failed for workspace #{workspace_id}, task #{task_type}: #{e.message}"
    end
    
    # Fallback to database
    WorkspaceTaskCompletion.exists?(
      company_workspace_id: workspace_id,
      task_type: task_type
    )
  end

  def markdown_to_html(text)
    return '' if text.blank?
    
    begin
      # Configure Redcarpet renderer with basic security
      renderer = Redcarpet::Render::HTML.new(
        filter_html: true,          # Filter out raw HTML for security
        no_links: false,            # Allow links
        no_images: false,           # Allow images
        safe_links_only: true,      # Only safe protocols
        with_toc_data: false,       # No TOC anchors
        hard_wrap: true,            # Convert newlines to <br>
        prettify: false             # Disable prettify for now
      )
      
      # Configure Markdown parser with common extensions
      markdown = Redcarpet::Markdown.new(renderer,
        autolink: true,                    # Auto-convert URLs to links
        tables: true,                      # Enable table support
        fenced_code_blocks: true,          # Enable ``` code blocks
        strikethrough: true,               # Enable ~~strikethrough~~
        superscript: false,                # Disable superscript for now
        underline: false,                  # Disable underline for now
        highlight: false,                  # Disable highlight for now
        quote: false,                      # Disable quote for now
        footnotes: false,                  # Disable footnotes for now
        no_intra_emphasis: true,           # Disable emphasis inside words
        space_after_headers: true          # Require space after # for headers
      )
      
      # Parse and return HTML-safe content
      markdown.render(text).html_safe
      
    rescue => e
      Rails.logger.error "Markdown parsing failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Fallback to simple_format for basic text formatting
      simple_format(h(text))
    end
  end
end
