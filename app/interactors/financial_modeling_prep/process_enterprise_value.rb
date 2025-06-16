class FinancialModelingPrep::ProcessEnterpriseValue < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    
    # Fetch enterprise value data
    fetch_enterprise_values(workspace)
    
    Rails.logger.info "Completed processing enterprise values for #{workspace.company_symbol}"
  end

  private

  def fetch_enterprise_values(workspace)
    context.url = "https://financialmodelingprep.com/stable/enterprise-values/#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}?apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    # Process last 3 years of enterprise value data
    context.response_result.first(3).each do |ev_data|
      year = Date.parse(ev_data['date']).year
      period = ev_data['date']
      
      # Store various enterprise value metrics as separate key ratios
      enterprise_value_ratios = {
        'Enterprise Value' => ev_data['enterpriseValue'],
        'Market Capitalization' => ev_data['marketCapitalization'],
        'Add Total Debt' => ev_data['addTotalDebt'],
        'Minus Cash And Cash Equivalents' => ev_data['minusCashAndCashEquivalents'],
        'Number Of Shares' => ev_data['numberOfShares'],
        'Stock Price' => ev_data['stockPrice']
      }
      
      enterprise_value_ratios.each do |ratio_name, ratio_value|
        next unless ratio_value
        
        # Skip if we already have this ratio for this period
        next if KeyRatio.exists?(
          company_workspace: workspace,
          ratio_name: ratio_name,
          period: period,
          year: year,
          ttm: false
        )
        
        KeyRatio.create!(
          company_workspace: workspace,
          ratio_name: ratio_name,
          ratio_value: ratio_value,
          period: period,
          year: year,
          ttm: false
        )
      end
    end
    
    Rails.logger.info "Stored enterprise values for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing enterprise values for #{workspace.company_symbol}: #{e.message}"
  end
end