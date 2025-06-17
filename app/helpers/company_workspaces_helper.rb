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

    # Parse the summary and extract key highlights based on filing type
    summary_content = filing.summary
    
    case filing.form_type
    when '10-K'
      render_10k_highlights(summary_content)
    when '10-Q'
      render_10q_highlights(summary_content)
    when '8-K'
      render_8k_highlights(summary_content)
    when 'DEF 14A'
      render_def14a_highlights(summary_content)
    else
      render_generic_highlights(summary_content)
    end
  end

  private

  def render_10k_highlights(summary)
    highlights = extract_financial_metrics(summary)
    
    content_tag :div, class: 'space-y-3' do
      if highlights.any?
        content_tag(:p, "The company reported strong financial results for fiscal year #{extract_year(summary)}:", class: 'text-sm text-gray-700 font-medium') +
        content_tag(:ul, class: 'list-disc list-inside space-y-1') do
          highlights.map do |highlight|
            content_tag(:li, highlight, class: 'text-sm text-gray-700')
          end.join.html_safe
        end +
        render_key_highlights_section(summary)
      else
        content_tag(:div, class: 'text-sm text-gray-700') do
          truncate(summary, length: 300)
        end
      end
    end
  end

  def render_10q_highlights(summary)
    content_tag :div, class: 'space-y-2' do
      content_tag(:div, class: 'text-sm text-gray-700') do
        truncate(summary, length: 200)
      end
    end
  end

  def render_8k_highlights(summary)
    content_tag :div, class: 'space-y-2' do
      content_tag(:div, class: 'text-sm text-gray-700') do
        truncate(summary, length: 200)
      end
    end
  end

  def render_def14a_highlights(summary)
    content_tag :div, class: 'space-y-2' do
      content_tag(:div, class: 'text-sm text-gray-700') do
        truncate(summary, length: 200)
      end
    end
  end

  def render_generic_highlights(summary)
    content_tag :div, class: 'space-y-2' do
      content_tag(:div, class: 'text-sm text-gray-700') do
        truncate(summary, length: 200)
      end
    end
  end

  def extract_financial_metrics(summary)
    metrics = []
    
    # Extract revenue information
    if summary.match(/Revenue:\s*\$?([\d.,]+\s*(?:billion|million))/i)
      revenue_match = summary.match(/Revenue:\s*(\$?[\d.,]+\s*(?:billion|million).*?)(?:\n|-)/i)
      metrics << revenue_match[1].strip if revenue_match
    end

    # Extract gross margin
    if summary.match(/Gross margin:\s*([\d.,%]+.*?)(?:\n|-)/i)
      margin_match = summary.match(/Gross margin:\s*([\d.,%]+.*?)(?:\n|-)/i)
      metrics << "Gross margin: #{margin_match[1].strip}" if margin_match
    end

    # Extract operating expenses
    if summary.match(/Operating expenses:\s*(\$?[\d.,]+\s*(?:billion|million).*?)(?:\n|-)/i)
      opex_match = summary.match(/Operating expenses:\s*(\$?[\d.,]+\s*(?:billion|million).*?)(?:\n|-)/i)
      metrics << "Operating expenses: #{opex_match[1].strip}" if opex_match
    end

    # Extract R&D expenses
    if summary.match(/R&D expenses:\s*(\$?[\d.,]+\s*(?:billion|million).*?)(?:\n|-)/i)
      rd_match = summary.match(/R&D expenses:\s*(\$?[\d.,]+\s*(?:billion|million).*?)(?:\n|-)/i)
      metrics << "R&D expenses: #{rd_match[1].strip}" if rd_match
    end

    # Extract net income
    if summary.match(/Net income:\s*(\$?[\d.,]+\s*(?:billion|million).*?)(?:\n|-)/i)
      ni_match = summary.match(/Net income:\s*(\$?[\d.,]+\s*(?:billion|million).*?)(?:\n|-)/i)
      metrics << "Net income: #{ni_match[1].strip}" if ni_match
    end

    # Extract EPS
    if summary.match(/EPS:\s*(\$?[\d.,]+.*?)(?:\n|-)/i)
      eps_match = summary.match(/EPS:\s*(\$?[\d.,]+.*?)(?:\n|-)/i)
      metrics << "EPS: #{eps_match[1].strip}" if eps_match
    end

    metrics.first(6) # Limit to 6 key metrics
  end

  def render_key_highlights_section(summary)
    # Look for "Key highlights:" section
    highlights_match = summary.match(/Key highlights:(.*?)(?:\n\n|\n[A-Z]|\z)/m)
    
    if highlights_match
      highlights_text = highlights_match[1].strip
      highlight_items = highlights_text.split(/\n-\s*/).reject(&:blank?)
      
      if highlight_items.any?
        content_tag(:div, class: 'mt-3') do
          content_tag(:p, 'Key highlights:', class: 'text-sm font-medium text-gray-700 mb-2') +
          content_tag(:ul, class: 'list-disc list-inside space-y-1') do
            highlight_items.first(4).map do |item|
              content_tag(:li, item.strip.gsub(/^-\s*/, ''), class: 'text-sm text-gray-600')
            end.join.html_safe
          end
        end
      end
    else
      ''.html_safe
    end
  end

  def extract_year(summary)
    # Try to extract the fiscal year from the summary
    year_match = summary.match(/(?:fiscal year|year)\s*(\d{4})/i)
    year_match ? year_match[1] : Date.current.year.to_s
  end
end 