class FinancialModelingPrep::ProcessKeyRatios < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    
    # Fetch financial ratios data
    fetch_annual_ratios(workspace)
    fetch_ttm_ratios(workspace)
    
    Rails.logger.info "Completed processing key ratios for #{workspace.company_symbol}"
  end

  private

  def fetch_annual_ratios(workspace)
    context.url = "https://financialmodelingprep.com/stable/ratios/#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}?apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    # Process last 3 years of annual ratios
    context.response_result.first(3).each do |ratio_data|
      store_ratios(workspace, ratio_data, false) # ttm = false for annual
    end
    
    Rails.logger.info "Stored annual ratios for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing annual ratios for #{workspace.company_symbol}: #{e.message}"
  end

  def fetch_ttm_ratios(workspace)
    sleep 0.5 # Rate limiting
    
    context.url = "https://financialmodelingprep.com/stable/ratios-ttm/#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}?apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    # Process TTM ratios
    ttm_data = context.response_result.first
    store_ratios(workspace, ttm_data, true) if ttm_data # ttm = true
    
    Rails.logger.info "Stored TTM ratios for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing TTM ratios for #{workspace.company_symbol}: #{e.message}"
  end

  def store_ratios(workspace, ratio_data, is_ttm)
    # Extract key ratios from the response
    ratios_to_store = {
      'currentRatio' => 'Current Ratio',
      'quickRatio' => 'Quick Ratio',
      'cashRatio' => 'Cash Ratio',
      'daysOfSalesOutstanding' => 'Days Sales Outstanding',
      'daysOfInventoryOutstanding' => 'Days Inventory Outstanding',
      'operatingCycle' => 'Operating Cycle',
      'daysOfPayablesOutstanding' => 'Days Payables Outstanding',
      'cashConversionCycle' => 'Cash Conversion Cycle',
      'grossProfitMargin' => 'Gross Profit Margin',
      'operatingProfitMargin' => 'Operating Profit Margin',
      'pretaxProfitMargin' => 'Pretax Profit Margin',
      'netProfitMargin' => 'Net Profit Margin',
      'effectiveTaxRate' => 'Effective Tax Rate',
      'returnOnAssets' => 'Return on Assets',
      'returnOnEquity' => 'Return on Equity',
      'returnOnCapitalEmployed' => 'Return on Capital Employed',
      'netIncomePerEBT' => 'Net Income per EBT',
      'ebtPerEbit' => 'EBT per EBIT',
      'ebitPerRevenue' => 'EBIT per Revenue',
      'debtRatio' => 'Debt Ratio',
      'debtEquityRatio' => 'Debt to Equity Ratio',
      'longTermDebtToCapitalization' => 'Long Term Debt to Capitalization',
      'totalDebtToCapitalization' => 'Total Debt to Capitalization',
      'interestCoverage' => 'Interest Coverage',
      'cashFlowToDebtRatio' => 'Cash Flow to Debt Ratio',
      'companyEquityMultiplier' => 'Equity Multiplier',
      'receivablesTurnover' => 'Receivables Turnover',
      'payablesTurnover' => 'Payables Turnover',
      'inventoryTurnover' => 'Inventory Turnover',
      'fixedAssetTurnover' => 'Fixed Asset Turnover',
      'assetTurnover' => 'Asset Turnover',
      'operatingCashFlowPerShare' => 'Operating Cash Flow per Share',
      'freeCashFlowPerShare' => 'Free Cash Flow per Share',
      'cashPerShare' => 'Cash per Share',
      'payoutRatio' => 'Payout Ratio',
      'operatingCashFlowSalesRatio' => 'Operating Cash Flow Sales Ratio',
      'freeCashFlowOperatingCashFlowRatio' => 'Free Cash Flow Operating Cash Flow Ratio',
      'cashFlowCoverageRatios' => 'Cash Flow Coverage Ratios',
      'shortTermCoverageRatios' => 'Short Term Coverage Ratios',
      'capitalExpenditureCoverageRatio' => 'Capital Expenditure Coverage Ratio',
      'dividendPaidAndCapexCoverageRatio' => 'Dividend Paid and Capex Coverage Ratio',
      'dividendPayoutRatio' => 'Dividend Payout Ratio',
      'priceBookValueRatio' => 'Price to Book Value Ratio',
      'priceToBookRatio' => 'Price to Book Ratio',
      'priceToSalesRatio' => 'Price to Sales Ratio',
      'priceEarningsRatio' => 'Price Earnings Ratio',
      'priceToFreeCashFlowsRatio' => 'Price to Free Cash Flows Ratio',
      'priceToOperatingCashFlowsRatio' => 'Price to Operating Cash Flows Ratio',
      'priceCashFlowRatio' => 'Price Cash Flow Ratio',
      'priceEarningsToGrowthRatio' => 'Price Earnings to Growth Ratio',
      'priceSalesRatio' => 'Price Sales Ratio',
      'dividendYield' => 'Dividend Yield',
      'enterpriseValueMultiple' => 'Enterprise Value Multiple',
      'priceFairValue' => 'Price Fair Value'
    }

    period = is_ttm ? 'TTM' : ratio_data['date']
    year = is_ttm ? Date.current.year : Date.parse(ratio_data['date']).year
    
    ratios_to_store.each do |api_key, display_name|
      next unless ratio_data[api_key]
      
      # Skip if we already have this ratio for this period
      next if KeyRatio.exists?(
        company_workspace: workspace,
        ratio_name: display_name,
        period: period,
        year: year,
        ttm: is_ttm
      )
      
      KeyRatio.create!(
        company_workspace: workspace,
        ratio_name: display_name,
        ratio_value: ratio_data[api_key],
        period: period,
        year: year,
        ttm: is_ttm
      )
    end
  end
end