class FinancialModelingPrep::ProcessKeyRatios < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    
    # Check if we've processed recently (within 1 day for incremental updates)
    # Exclude enterprise value ratios as they're handled by a separate processor
    enterprise_value_ratios = ['Enterprise Value', 'Market Capitalization', 'Add Total Debt', 'Minus Cash And Cash Equivalents', 'Number Of Shares', 'Stock Price']
    last_processed = workspace.key_ratios.where.not(ratio_name: enterprise_value_ratios).maximum(:updated_at)
    if last_processed && last_processed > 1.day.ago
      Rails.logger.info "Key ratios for #{workspace.company_symbol} are up to date"
      return
    end
    
    # Fetch financial ratios data
    fetch_annual_ratios(workspace)
    fetch_ttm_ratios(workspace)
    
    Rails.logger.info "Completed processing key ratios for #{workspace.company_symbol}"
  end

  private

  def fetch_annual_ratios(workspace)
    context.url = "https://financialmodelingprep.com/stable/ratios?symbol=#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
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
    
    context.url = "https://financialmodelingprep.com/stable/ratios-ttm?symbol=#{workspace.company_symbol}"
    
    # Call API directly
    response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
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
    base_ratios_mapping = {
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
      'debtToAssetsRatio' => 'Debt Ratio',
      'debtToEquityRatio' => 'Debt to Equity Ratio',
      'longTermDebtToCapitalRatio' => 'Long Term Debt to Capitalization',
      'totalDebtToCapitalization' => 'Total Debt to Capitalization',
      'interestCoverageRatio' => 'Interest Coverage',
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

    # For TTM data, we need to check for fields with "TTM" suffix
    # For annual data, we use the base field names
    ratios_to_store = if is_ttm
      # Create mapping for TTM field names
      ttm_mapping = {}
      base_ratios_mapping.each do |base_key, display_name|
        ttm_key = "#{base_key}TTM"
        ttm_mapping[ttm_key] = display_name
      end
      ttm_mapping
    else
      base_ratios_mapping
    end

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