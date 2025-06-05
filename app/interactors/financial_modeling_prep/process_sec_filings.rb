class FinancialModelingPrep::ProcessSecFilings < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    from_date = 2.years.ago.beginning_of_year
    to_date = Date.current
    context.url = "https://financialmodelingprep.com/stable/sec-filings-search/symbol?symbol=#{workspace.company_symbol}&from=#{from_date.strftime('%Y-%m-%d')}&to=#{to_date.strftime('%Y-%m-%d')}&page=0&limit=100"
    
    super
    
    # TODO: WHERE I LEFT OFF: Make sure the response is an array of hashes that can be processed by process_filings
    process_filings(context.response, workspace)
  end

  private

  def process_filings(filings, workspace)
    filings.each do |filing|
      # Store basic filing metadata
      sec_filing = SecFiling.create!(
        company_workspace: workspace,
        cik: filing['cik'],
        filing_date: filing['filingDate'],
        form_type: filing['formType'],
        sec_link: filing['link'],
        final_link: filing['finalLink'],
      )

      # Process important filings with LLM
      if important_filing?(filing['formType'])
        generate_important_filing_summary(sec_filing)
      end
    end
  end

  def important_filing?(form_type)
    %w[10-K 10-Q 8-K].include?(form_type)
  end

  def generate_important_filing_summary(sec_filing)
    # Fetch the filing content
    filing_content = fetch_filing_content(sec_filing.final_link)
    
    # Generate summary using LLM
    summary = generate_filing_summary(filing_content, sec_filing.form_type)
    
    # Store the summary
    sec_filing.update!(
      summary:,
      processed_at: Time.current
    )
  end

  def fetch_filing_content(url)
    # Implement fetching logic here
    # You might want to use a service like SEC's EDGAR API
    # or parse the HTML/XML content from the final_link
  end

  def generate_filing_summary(content, form_type)
    # Use your preferred LLM to generate a summary
    # Different prompts for different form types
    case form_type
    when '10-K'
      prompt = "Summarize this annual report, focusing on key financial metrics, risks, and business strategy..."
    when '10-Q'
      prompt = "Summarize this quarterly report, focusing on recent performance and significant changes..."
    when '8-K'
      prompt = "Summarize this current report, focusing on the material event and its implications..."
    end
    
    # Call your LLM service here
    # return llm_service.generate_summary(content, prompt)
  end
end