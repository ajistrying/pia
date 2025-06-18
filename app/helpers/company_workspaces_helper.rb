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

  # Analyst Ratings Calculations
  def calculate_analyst_consensus(workspace)
    return nil unless workspace.analyst_ratings.any?

    # Filter for Year-to-Date ratings only (current year)
    current_year = Date.current.year
    ytd_ratings = workspace.analyst_ratings.where(
      "created_date >= ?",
      Date.new(current_year, 1, 1)
    )
    
    return nil unless ytd_ratings.any?
    
    total_ratings = ytd_ratings.count
    
    # Count ratings by category using more sophisticated logic
    buy_ratings = 0
    hold_ratings = 0
    sell_ratings = 0
    
    ytd_ratings.each do |rating|
      category = categorize_analyst_rating(rating.rating)
      case category
      when :buy
        buy_ratings += 1
      when :hold
        hold_ratings += 1
      when :sell
        sell_ratings += 1
      else
        next
      end
    end
    
    # Calculate average price target (only for YTD ratings that have targets)
    avg_price_target = ytd_ratings.where.not(price_target: nil).average(:price_target)
    
    # Calculate consensus using weighted scoring system (Buy=1, Hold=3, Sell=5)
    consensus_score = (buy_ratings * 1.0 + hold_ratings * 3.0 + sell_ratings * 5.0) / total_ratings
    
    # Determine consensus rating based on score
    consensus_rating = case consensus_score
    when 0..1.5
      'Strong Buy'
    when 1.5..2.5
      'Moderate Buy'
    when 2.5..3.5
      'Hold'
    when 3.5..4.5
      'Moderate Sell'
    else
      'Strong Sell'
    end
    
    # Normalize to moderate if fewer than 3 ratings for strong ratings
    if total_ratings < 3
      consensus_rating = 'Moderate Buy' if consensus_rating == 'Strong Buy'
      consensus_rating = 'Moderate Sell' if consensus_rating == 'Strong Sell'
    end

    # Calculate the date range for context
    oldest_ytd_rating = ytd_ratings.minimum(:created_date) || ytd_ratings.minimum(:created_at)&.to_date
    newest_ytd_rating = ytd_ratings.maximum(:created_date) || ytd_ratings.maximum(:created_at)&.to_date

    {
      total_ratings: total_ratings,
      buy_ratings: buy_ratings,
      hold_ratings: hold_ratings,
      sell_ratings: sell_ratings,
      avg_price_target: avg_price_target,
      consensus_rating: consensus_rating,
      consensus_score: consensus_score,
      date_range: {
        start: oldest_ytd_rating,
        end: newest_ytd_rating
      },
      is_ytd_filtered: true
    }
  end

  private

  def categorize_analyst_rating(rating_string)
    return nil unless rating_string.present? && rating_string.include?(">")
    
    # Normalize the rating string for analysis
    normalized_rating = rating_string.downcase.strip
    
    # Handle transition ratings (e.g., "Buy -> Hold", "Outperform -> Underperform")
    if normalized_rating.include?(' -> ')
      # For transitions, use the final (current) rating
      current_rating = normalized_rating.split(' -> ').last.strip
    else
      current_rating = normalized_rating
    end
    
    # Categorize based on the current/final rating
    case current_rating
    when /\b(strong buy|buy|outperform|overweight|positive|accumulate)\b/
      :buy
    when /\b(strong sell|sell|underperform|underweight|negative|reduce)\b/
      :sell
    when /\b(hold|neutral|market perform|sector weight|equal weight|maintain)\b/
      :hold
    else
      # Default fallback - try to infer from common patterns
      if normalized_rating.include?('upgrade') || normalized_rating.include?('raised')
        :buy
      elsif normalized_rating.include?('downgrade') || normalized_rating.include?('lowered')
        :sell
      else
        :hold  # Default to hold for unknown ratings
      end
    end
  end

  public

  def consensus_rating_color(consensus_rating)
    case consensus_rating
    when 'Strong Buy', 'Moderate Buy'
      'text-green-600'
    when 'Hold'
      'text-yellow-600'
    when 'Moderate Sell', 'Strong Sell'
      'text-red-600'
    else
      'text-gray-600'
    end
  end

  def rating_change_color(rating)
    if rating.include?("Buy")
      'text-green-600'
    elsif rating.include?("Hold")
      'text-yellow-600'
    else
      'text-red-600'
    end
  end

  # Financial formatting helper
  def format_financial_number(number, unit: 'B')
    return 'N/A' unless number.present?
    
    case unit
    when 'B'
      number_to_currency(number / 1_000_000_000, precision: 1) + "B"
    when 'M'
      number_to_currency(number / 1_000_000, precision: 1) + "M"
    else
      number_to_currency(number, precision: 2)
    end
  end
end 