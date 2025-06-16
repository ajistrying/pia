class FinancialModelingPrep::ProcessSecFilings < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    
    # Check if we've processed recently (within 1 day for incremental updates)
    last_processed = workspace.sec_filings.maximum(:updated_at)
    if last_processed && last_processed > 1.day.ago
      Rails.logger.info "SEC filings for #{workspace.company_symbol} are up to date"
      return
    end
    
    # Fetch only new filings since last update
    from_date = last_processed&.to_date || 3.years.ago.beginning_of_year
    to_date = Date.current
    
    process_incremental_filings(workspace, from_date, to_date)
  end

  private

  def process_incremental_filings(workspace, from_date, to_date)
    all_filings = []
    page = 0
    limit = 100
    
    # Only fetch what we need
    loop do
      context.url = "https://financialmodelingprep.com/stable/sec-filings-search/symbol?symbol=#{workspace.company_symbol}&from=#{from_date.strftime('%Y-%m-%d')}&to=#{to_date.strftime('%Y-%m-%d')}&page=#{page}&limit=#{limit}"
      
      # Call the parent class method to fetch data
      response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
      context.response_result = JSON.parse(response.body)
      
      current_page_filings = context.response_result
      break if current_page_filings.nil? || current_page_filings.empty?
      
      # Filter to only important filings immediately
      important_filings = current_page_filings.select { |filing| important_filing?(filing['formType']) }
      all_filings.concat(important_filings)
      
      break if current_page_filings.length < limit
      page += 1
      break if page > 10  # Limit for incremental updates
      
      sleep 0.1  # Reduced delay for faster processing
    end
    
    Rails.logger.info "Fetched #{all_filings.length} new important SEC filings for #{workspace.company_symbol}"
    
    # Process in batches to avoid memory issues
    all_filings.in_groups_of(5, false) do |filing_batch|
      process_filing_batch(filing_batch, workspace)
    end
  end

  def process_filing_batch(filings, workspace)
    filings.each do |filing|
      # Skip if already exists
      next if SecFiling.exists?(
        company_workspace: workspace,
        cik: filing['cik'],
        filing_date: filing['filingDate'],
        form_type: filing['formType']
      )
      
      sec_filing = SecFiling.create!(
        company_workspace: workspace,
        cik: filing['cik'],
        filing_date: filing['filingDate'],
        form_type: filing['formType'],
        sec_link: filing['link'],
        final_link: filing['finalLink']
      )

      # Queue summary generation as separate job to avoid blocking
      GenerateFilingSummaryJob.perform_later(sec_filing.id)
    end
  end

  def important_filing?(form_type)
    ['10-K', '10-Q', '8-K', 'DEF 14A'].include?(form_type)
  end
end