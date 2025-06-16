class GenerateFilingSummaryJob < ApplicationJob
  queue_as :ai_processing
  
  def perform(sec_filing_id)
    sec_filing = SecFiling.find(sec_filing_id)
    
    # Generate summary immediately since we know it's important
    generate_important_filing_summary(sec_filing)
  end

  private

  def generate_important_filing_summary(sec_filing)
    # Fetch the filing content
    filing_content = fetch_filing_content(sec_filing.final_link)

    return unless filing_content
    
    summary = generate_filing_summary(filing_content, sec_filing.form_type)

    return unless summary
        
    sec_filing.update!(
      summary: summary,
      processed_at: Time.current
    )
  end

  def fetch_filing_content(url)
    sleep 0.5
    
    response = Faraday.new do |faraday|
      faraday.headers['User-Agent'] = 'YourCompany Pia/1.0 (wjohnson@eleudev.com)'
      faraday.options.timeout = 30
      faraday.options.open_timeout = 10
    end.get(url)

    unless response.success?
      Rails.logger.error "Error fetching SEC filing #{url}: #{response.status}"
      return nil
    end

    doc = Nokogiri::HTML(response.body)
    doc.css('script, style, nav, header, footer').remove
    
    doc.text
      .gsub(/\s+/, ' ')           # Normalize whitespace
      .gsub(/\n+/, "\n")          # Clean up line breaks
      .strip

  rescue Faraday::TimeoutError => e
    Rails.logger.warn "SEC filing fetch timeout: #{url}"
    nil
  rescue => e
    Rails.logger.error "Error fetching SEC filing #{url}: #{e.message}"
    nil
  end

  def generate_filing_summary(content, form_type)
    # Create comprehensive prompts based on filing type
    prompt = case form_type
    when '10-K'
      build_10k_prompt
    when '10-Q'
      build_10q_prompt
    when '8-K'
      build_8k_prompt
    when 'DEF 14A'
      build_def14a_prompt
    else
      "Provide a comprehensive investment-focused summary of this SEC filing."
    end

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

  def build_10k_prompt
    <<~PROMPT
      You are an expert financial analyst. Analyze this 10-K annual report and provide a comprehensive investment summary. Focus on:

      **FINANCIAL PERFORMANCE & METRICS:**
      - Revenue trends, growth rates, and seasonality patterns
      - Profitability metrics (gross, operating, net margins)
      - Key financial ratios (ROE, ROA, debt-to-equity, current ratio)
      - Cash flow analysis (operating, investing, financing)
      - Capital allocation strategy (dividends, buybacks, reinvestment)

      **BUSINESS STRATEGY & COMPETITIVE POSITION:**
      - Core business segments and revenue contributions
      - Competitive advantages and moats
      - Market position and market share trends
      - Strategic initiatives and growth investments
      - R&D spending and innovation pipeline

      **RISK FACTORS & CONCERNS:**
      - Top 5 most material business risks
      - Regulatory risks and compliance issues
      - Market/economic sensitivity
      - Operational risks and dependencies
      - Financial risks (liquidity, credit, interest rate)

      **MANAGEMENT OUTLOOK & GUIDANCE:**
      - Forward-looking statements and guidance
      - Capital expenditure plans
      - Market expansion plans
      - Expected headwinds and tailwinds

      **INVESTMENT THESIS IMPLICATIONS:**
      - Long-term growth prospects (3-5 years)
      - Dividend sustainability and growth potential
      - Valuation considerations vs peers
      - Key catalysts to monitor
      - Red flags or concerns for investors

      Format your response with clear sections and bullet points. Be objective and highlight both opportunities and risks.
    PROMPT
  end

  def build_10q_prompt
    <<~PROMPT
      You are an expert financial analyst. Analyze this 10-Q quarterly report and provide a comprehensive investment summary. Focus on:

      **QUARTERLY PERFORMANCE:**
      - Revenue performance vs prior quarter and year-over-year
      - Margin trends (gross, operating, net) and drivers
      - Earnings quality and one-time items
      - Segment performance and geographic breakdown
      - Sequential trends and seasonality factors

      **FINANCIAL POSITION CHANGES:**
      - Balance sheet changes from prior quarter
      - Cash position and debt levels
      - Working capital trends
      - Capital expenditures and investments
      - Share count changes (buybacks, dilution)

      **BUSINESS DEVELOPMENTS:**
      - Operational highlights and achievements
      - New product launches or service offerings
      - Market share gains/losses
      - Strategic partnerships or acquisitions
      - Management commentary on business trends

      **FORWARD-LOOKING INDICATORS:**
      - Updated guidance or outlook statements
      - Management commentary on future quarters
      - Order backlog or pipeline changes
      - Seasonal expectations
      - Macro environment impact

      **INVESTMENT IMPLICATIONS:**
      - Progress toward annual goals
      - Trend sustainability analysis
      - Relative performance vs competitors
      - Key metrics to watch next quarter
      - Potential surprises or catalysts

      **RISKS & CONCERNS:**
      - Near-term headwinds
      - Margin pressure sources
      - Market or competitive challenges
      - Operational issues

      Format your response with clear sections and bullet points. Focus on changes from previous periods and forward-looking trends.
    PROMPT
  end

  def build_8k_prompt
    <<~PROMPT
      You are an expert financial analyst. Analyze this 8-K current report and provide a comprehensive investment summary. Focus on:

      **MATERIAL EVENT ANALYSIS:**
      - Specific event or announcement details
      - Immediate financial impact (if quantified)
      - Strategic significance for the business
      - Timeline and implementation details
      - Comparison to market expectations

      **INVESTMENT IMPACT ASSESSMENT:**
      - Short-term stock price implications
      - Long-term strategic value creation/destruction
      - Impact on competitive position
      - Financial model adjustments needed
      - Valuation multiple implications

      **STAKEHOLDER IMPLICATIONS:**
      - Impact on shareholders (dilution, returns)
      - Creditor impact (debt capacity, covenants)
      - Customer/supplier relationships
      - Employee impact (layoffs, hiring, compensation)
      - Regulatory implications

      **RISK ASSESSMENT:**
      - Execution risks for the announced event
      - Market reaction risks
      - Integration risks (for M&A)
      - Regulatory approval risks
      - Opportunity costs

      **CONTEXT & COMPARISONS:**
      - How this fits company's strategic plan
      - Historical precedent for similar events
      - Peer company comparisons
      - Market/industry context
      - Management track record on similar initiatives

      **INVESTMENT DECISION FACTORS:**
      - Key questions for management
      - Metrics to monitor post-announcement
      - Timeframe for benefits/impact
      - Contingency scenarios
      - Buy/sell/hold implications

      Format your response with clear sections and bullet points. Be specific about the investment implications and what investors should monitor.
    PROMPT
  end

  def build_def14a_prompt
    <<~PROMPT
      You are an expert financial analyst. Analyze this DEF 14A proxy statement and provide a comprehensive investment summary. Focus on:

      **CORPORATE GOVERNANCE:**
      - Board composition and independence
      - Director qualifications and experience
      - Board diversity and tenure
      - Committee structure and effectiveness
      - Governance best practices and concerns

      **EXECUTIVE COMPENSATION:**
      - CEO and executive pay levels vs performance
      - Pay-for-performance alignment
      - Compensation structure (base, bonus, equity)
      - Peer group comparisons
      - Say-on-pay voting history and concerns

      **SHAREHOLDER PROPOSALS:**
      - Management proposals and rationale
      - Shareholder-initiated proposals
      - Board recommendations and reasoning
      - Voting implications for shareholders
      - Activist investor involvement

      **MANAGEMENT ACCOUNTABILITY:**
      - Executive performance metrics
      - Long-term incentive plan design
      - Clawback provisions and risk management
      - Succession planning transparency
      - Historical pay vs performance correlation

      **INVESTMENT GOVERNANCE IMPLICATIONS:**
      - Capital allocation oversight
      - Strategic decision-making process
      - Risk management framework
      - Shareholder rights and protections
      - ESG (Environmental, Social, Governance) initiatives

      **VOTING RECOMMENDATIONS:**
      - Key proposals requiring shareholder vote
      - Investment thesis alignment with proposals
      - Potential conflicts of interest
      - Long-term value creation considerations
      - Activist campaign assessment (if applicable)

      **RED FLAGS & POSITIVE INDICATORS:**
      - Governance best practices
      - Compensation red flags
      - Board effectiveness indicators
      - Shareholder-friendly policies
      - Transparency and disclosure quality

      Format your response with clear sections and bullet points. Focus on governance quality and long-term value creation alignment.
    PROMPT
  end
end