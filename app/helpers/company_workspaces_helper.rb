module CompanyWorkspacesHelper
  def get_filing_icon(form_type)
    case form_type
    when '10-K'
      '<i class="fas fa-file-alt"></i>'.html_safe
    when '10-Q'
      '<i class="fas fa-chart-bar"></i>'.html_safe
    when '8-K'
      '<i class="fas fa-bullhorn"></i>'.html_safe
    when 'DEF 14A'
      '<i class="fas fa-vote-yea"></i>'.html_safe
    when '20-F'
      '<i class="fas fa-globe"></i>'.html_safe
    else
      '<i class="fas fa-file"></i>'.html_safe
    end
  end

  def get_filing_title(form_type)
    case form_type
    when '10-K'
      'Annual Report (10-K)'
    when '10-Q'
      'Quarterly Report (10-Q)'
    when '8-K'
      'Current Report (8-K)'
    when 'DEF 14A'
      'Proxy Statement (DEF 14A)'
    when '20-F'
      'Annual Report (20-F)'
    else
      "#{form_type} Filing"
    end
  end

  def render_filing_highlights(filing)
    return '' unless filing.summary.present?

    # Since summaries are already AI-generated and well-structured,
    # just show a preview with consistent length
    content_tag :div, class: 'text-sm text-gray-700' do
      truncate(filing.summary, length: 250)
    end
  end
end 