class FinancialModelingPrep::RefreshNews < FinancialModelingPrep::BaseInteractor
  def call
    context.workspace = CompanyWorkspace.find(context.workspace_id)

    context.fail!(message: "Sorry, unable to locate this workspace. Refresh the page and try again a bit later.") if context.workspace.nil?

    begin
      fetch_fmp_articles(context.workspace)
      sleep 0.5
      fetch_stock_specific_news(context.workspace)
      sleep 0.5
      fetch_general_news(context.workspace)

      Rails.logger.info "Completed processing news for #{context.workspace.company_symbol}"
    rescue => e
      context.fail!(message: "Error processing news: #{e.message}")
    end
  end

  private

  def make_api_call(url)
    response = Faraday.get("#{url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    JSON.parse(response.body)
  end

  def fetch_fmp_articles(workspace)
    context.url = "https://financialmodelingprep.com/stable/fmp-articles?page=0&limit=50"
    response = make_api_call(context.url)
    process_fmp_articles(response, context.workspace)
    Rails.logger.info "Completed fetch_fmp_articles for #{context.workspace.company_symbol}"
  end

  def fetch_stock_specific_news(workspace)
    context.url = "https://financialmodelingprep.com/stable/news/stock?symbols=#{workspace.company_symbol}&from=#{(Date.current - 1.week).strftime('%Y-%m-%d')}"
    response = make_api_call(context.url)
    process_stock_specific_news(response, context.workspace)
    Rails.logger.info "Completed fetch_stock_specific_news for #{context.workspace.company_symbol}"
  end

  def fetch_general_news(workspace)
    last_pulled_at = workspace.last_successful_update.strftime('%Y-%m-%d')
    context.url = "https://financialmodelingprep.com/stable/news/general?from=#{last_pulled_at}"
    response = make_api_call(context.url)
    process_general_news(response, context.workspace)
    Rails.logger.info "Completed fetch_general_news for #{context.workspace.company_symbol}"
  end

  # https://site.financialmodelingprep.com/developer/docs/stable#fmp-articles
  def process_fmp_articles(response, workspace)
    response.each do |article|
      next unless article['tickers'].include?(workspace.company_symbol)
      next if NewsPiece.exists?(url: article['link'])
      NewsPiece.create( 
        company_workspace: workspace,
        title: article['title'],
        author: article['author'],
        content: article['content'],
        url: article['link'],
        summary: generate_news_summary(article['content'], workspace.company_symbol),
        published_date: article['date'].to_datetime
      )
    end
  end

  # https://site.financialmodelingprep.com/developer/docs/stable#stock-news
  def process_stock_specific_news(response, workspace)
    response.each do |news|
      next if NewsPiece.exists?(url: news['url'])
      NewsPiece.create(
        company_workspace: workspace,
        title: news['title'],
        author: news['publisher'],
        content: news['text'],
        url: news['url'],
        summary: generate_news_summary(news['text'], workspace.company_symbol),
        published_date: news['publishedDate'].to_datetime
      )
    end
  end

  # https://site.financialmodelingprep.com/developer/docs/stable#general-news
  def process_general_news(response, workspace)
    response.each do |news|
      next if NewsPiece.exists?(url: news['url'])
      NewsPiece.create(
        company_workspace: workspace,
        title: news['title'],
        author: news['publisher'],
        content: news['text'],
        url: news['url'],
        summary: generate_news_summary(news['text'], workspace.company_symbol),
        published_date: news['publishedDate'].to_datetime
      )
    end
  end

  def generate_news_summary(content, company_symbol)
    return nil if content.blank?
    
    prompt = <<~PROMPT
      You are a financial analyst summarizing a news article about #{company_symbol}. Create a concise summary that covers:

      **KEY POINTS:**
      - Most important facts and developments
      - Financial impact or implications
      - Strategic significance for the company
      - Market context and competitive implications

      **INVESTMENT RELEVANCE:**
      - How this news affects the company's prospects
      - Potential impact on stock price or valuation
      - Timeline for impact (immediate vs long-term)
      - Risk factors or opportunities highlighted

      **CONCLUSION:**
      - Overall significance for investors
      - Key takeaway in 1-2 sentences

      Keep the summary under 300 words but ensure all critical information is captured. Focus on actionable insights for investment decisions.
    PROMPT

    # Call OpenAI API
    begin
      client = OpenAI::Client.new(api_key: ENV['OPENAI_API_KEY'])
      response = client.chat.completions.create(
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: content }
        ],
        max_tokens: 1500,
        temperature: 0.3
      )
      
      response.choices.first.message.content
      
    rescue => e
      Rails.logger.error "OpenAI API error: #{e.message}"
      nil
    end
  end
end