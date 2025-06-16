class FinancialModelingPrep::ProcessAnalystRatings < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    
    # Fetch analyst ratings data
    fetch_grades(workspace)
    fetch_price_target_summary(workspace)
    fetch_price_target_consensus(workspace)
    
    Rails.logger.info "Completed processing analyst ratings for #{workspace.company_symbol}"
  end

  private

  def fetch_grades(workspace)
    context.url = "https://financialmodelingprep.com/stable/grades?symbol=#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    context.response_result.each do |grade_data|
      # Skip if we already have this rating
      next if AnalystRating.exists?(
        company_workspace: workspace,
        rating_agency: grade_data['gradingCompany'],
        created_date: Date.parse(grade_data['date'])
      )
      
      AnalystRating.create!(
        company_workspace: workspace,
        rating_agency: grade_data['gradingCompany'],
        rating: "#{grade_data['previousGrade']} -> #{grade_data['newGrade']}",
        analyst_name: grade_data['gradingCompany'],
        notes: "Action: #{grade_data['action']}",
        created_date: Date.parse(grade_data['date'])
      )
    end
    
    Rails.logger.info "Stored #{context.response_result.length} stock grades for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing stock grades for #{workspace.company_symbol}: #{e.message}"
  end

  def fetch_price_target_summary(workspace)
    sleep 0.5 # Rate limiting
    
    context.url = "https://financialmodelingprep.com/stable/price-target-summary?symbol=#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    # Price target summary returns aggregated data
    summary_data = context.response_result.first
    
    if summary_data
      AnalystRating.create!(
        company_workspace: workspace,
        rating_agency: "Consensus",
        rating: "Price Target Summary",
        price_target: summary_data['lastMonth']&.to_f,
        notes: "Last Month: #{summary_data['lastMonth']}, Last Quarter: #{summary_data['lastQuarter']}, Last Year: #{summary_data['lastYear']}",
        created_date: Date.current
      )
    end
    
    Rails.logger.info "Stored price target summary for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing price target summary for #{workspace.company_symbol}: #{e.message}"
  end

  def fetch_price_target_consensus(workspace)
    sleep 0.5 # Rate limiting
    
    context.url = "https://financialmodelingprep.com/stable/price-target-consensus?symbol=#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    # Consensus data
    consensus_data = context.response_result.first
    
    if consensus_data
      AnalystRating.create!(
        company_workspace: workspace,
        rating_agency: "Consensus",
        rating: consensus_data['targetConsensus'],
        price_target: consensus_data['targetConsensus']&.to_f,
        notes: "Target High: #{consensus_data['targetHigh']}, Target Low: #{consensus_data['targetLow']}, Target Median: #{consensus_data['targetMedian']}",
        created_date: Date.current
      )
    end
    
    Rails.logger.info "Stored price target consensus for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing price target consensus for #{workspace.company_symbol}: #{e.message}"
  end
end