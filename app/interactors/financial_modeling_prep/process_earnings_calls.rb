class FinancialModelingPrep::ProcessEarningsCalls < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    start_year = 3.years.ago.year
    start_quarter = 1
    end_year = Date.current.year
    end_quarter = 4

    (start_year..end_year).each do |year|
      (start_quarter..end_quarter).each do |quarter|
        url = "https://financialmodelingprep.com/stable/earning-call-transcript?symbol=#{workspace.company_symbol}&year=#{year}&quarter=#{quarter}"

        # Call API directly for each quarter
        response = Faraday.get("#{url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
        response_result = JSON.parse(response.body)

        next if response_result.nil? || response_result.empty?

        response_result.each do |earnings_call|
          EarningsCall.create!(
            company_workspace: workspace,
            year: year,
            quarter: quarter,
            transcript: earnings_call['content'],
            summary: generate_summary(earnings_call['content'])
          )
        end
      end
    end
  end

  private

  def generate_summary(transcript)
    prompt = <<~PROMPT
      You are a financial analyst summarizing an earnings call transcript. Create a comprehensive summary that covers:

      **FINANCIAL HIGHLIGHTS:**
      - Revenue, earnings, and key financial metrics vs. previous periods and guidance
      - Margin performance and trends
      - Cash flow and balance sheet highlights

      **BUSINESS PERFORMANCE:**
      - Key operational metrics and KPIs
      - Segment/division performance
      - Major business developments or strategic initiatives

      **FORWARD GUIDANCE:**
      - Management's outlook for next quarter/year
      - Any revised guidance or forecasts
      - Key assumptions behind projections

      **MANAGEMENT COMMENTARY:**
      - CEO/CFO key themes and strategic focus
      - Market conditions and competitive landscape
      - Challenges and opportunities discussed

      **Q&A INSIGHTS:**
      - Most important analyst questions and management responses
      - Any concerning issues raised
      - Management's confidence level on key topics

      **KEY TAKEAWAYS:**
      - 3-5 most important points for investors
      - Any surprises or notable items
      - Overall tone (bullish/neutral/cautious)

      Format the summary in clear sections with bullet points. Keep it under 500 words but ensure all critical information is captured. Focus on actionable insights for investment decisions.
    PROMPT

    content = transcript

    # Call OpenAI API with correct format for v0.6.0
    begin
      client = OpenAI::Client.new(api_key: ENV['OPENAI_API_KEY'])
      response = client.chat.completions.create(
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: content }
        ],
        max_tokens: 2000,
        temperature: 0.3
      )
      
      response.choices.first.message.content
      
    rescue => e
      Rails.logger.error "OpenAI API error: #{e.message}"
      nil
    end
  end
end