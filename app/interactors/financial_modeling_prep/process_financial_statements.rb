class FinancialModelingPrep::ProcessFinancialStatements < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    
    # Check if we've processed recently (within 1 day for incremental updates)
    last_processed = workspace.financial_statements.maximum(:updated_at)
    if last_processed && last_processed > 1.day.ago
      Rails.logger.info "Financial statements for #{workspace.company_symbol} are up to date"
      return
    end
    
    # Fetch financial statements data (last 3 years)
    fetch_income_statements(workspace)
    fetch_balance_sheets(workspace)
    fetch_cash_flow_statements(workspace)
    
    Rails.logger.info "Completed processing financial statements for #{workspace.company_symbol}"
  end

  private

  def fetch_income_statements(workspace)
    url = "https://financialmodelingprep.com/stable/income-statement?symbol=#{workspace.company_symbol}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}"
    
    # Call API directly with proper error handling
    response = Faraday.get(url)

    Rails.logger.info "Response from income statements API: #{response.body}"
    
    # Check if response is valid JSON before parsing
    if response.body.strip.start_with?('{', '[')
      begin
        response_result = JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parsing error for income statements API: #{e.message}. Response body: #{response.body[0..200]}"
        return
      end
    else
      Rails.logger.warn "Non-JSON response from income statements API: #{response.body[0..200]}"
      return
    end
    
    return unless response_result.is_a?(Array) && !response_result.empty?
    
    # Process last 3 years of annual data
    response_result.first(3).each do |statement|
      next if FinancialStatement.exists?(
        company_workspace: workspace,
        statement_type: 'income_statement',
        period: statement['date'],
        year: Date.parse(statement['date']).year
      )
      
      FinancialStatement.create!(
        company_workspace: workspace,
        statement_type: 'income_statement',
        period: statement['date'],
        year: Date.parse(statement['date']).year,
        revenue: statement['revenue'],
        gross_profit: statement['grossProfit'],
        operating_income: statement['operatingIncome'],
        net_income: statement['netIncome'],
        eps: statement['eps']
      )
    end
    
    Rails.logger.info "Stored income statements for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing income statements for #{workspace.company_symbol}: #{e.message}"
  end

  def fetch_balance_sheets(workspace)
    sleep 0.5 # Rate limiting
    
    url = "https://financialmodelingprep.com/stable/balance-sheet-statement?symbol=#{workspace.company_symbol}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}"
    
    # Call API directly with proper error handling
    response = Faraday.get(url)

    Rails.logger.info "Response from balance sheets API: #{response.body}"
    # Check if response is valid JSON before parsing
    if response.body.strip.start_with?('{', '[')
      begin
        response_result = JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parsing error for balance sheets API: #{e.message}. Response body: #{response.body[0..200]}"
        return
      end
    else
      Rails.logger.warn "Non-JSON response from balance sheets API: #{response.body[0..200]}"
      return
    end
    
    return unless response_result.is_a?(Array) && !response_result.empty?
    
    # Process last 3 years of annual data
    response_result.first(3).each do |statement|
      next if FinancialStatement.exists?(
        company_workspace: workspace,
        statement_type: 'balance_sheet',
        period: statement['date'],
        year: Date.parse(statement['date']).year
      )
      
      FinancialStatement.create!(
        company_workspace: workspace,
        statement_type: 'balance_sheet',
        period: statement['date'],
        year: Date.parse(statement['date']).year,
        total_assets: statement['totalAssets'],
        total_debt: statement['totalDebt'],
        shareholders_equity: statement['totalStockholdersEquity']
      )
    end
    
    Rails.logger.info "Stored balance sheets for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing balance sheets for #{workspace.company_symbol}: #{e.message}"
  end

  def fetch_cash_flow_statements(workspace)
    sleep 0.5 # Rate limiting
    
    url = "https://financialmodelingprep.com/stable/cash-flow-statement?symbol=#{workspace.company_symbol}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}"
    
    # Call API directly with proper error handling
    response = Faraday.get(url)

    Rails.logger.info "Response from cash flow statements API: #{response.body}"
    # Check if response is valid JSON before parsing
    if response.body.strip.start_with?('{', '[')
      begin
        response_result = JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parsing error for cash flow statements API: #{e.message}. Response body: #{response.body[0..200]}"
        return
      end
    else
      Rails.logger.warn "Non-JSON response from cash flow statements API: #{response.body[0..200]}"
      return
    end
    
    return unless response_result.is_a?(Array) && !response_result.empty?
    
    # Process last 3 years of annual data
    response_result.first(3).each do |statement|
      next if FinancialStatement.exists?(
        company_workspace: workspace,
        statement_type: 'cash_flow_statement',
        period: statement['date'],
        year: Date.parse(statement['date']).year
      )
      
      FinancialStatement.create!(
        company_workspace: workspace,
        statement_type: 'cash_flow_statement',
        period: statement['date'],
        year: Date.parse(statement['date']).year,
        operating_cash_flow: statement['netCashProvidedByOperatingActivities'],
        free_cash_flow: statement['freeCashFlow']
      )
    end
    
    Rails.logger.info "Stored cash flow statements for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing cash flow statements for #{workspace.company_symbol}: #{e.message}"
  end
end