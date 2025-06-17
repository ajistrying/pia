class FinancialModelingPrep::ProcessNews < FinancialModelingPrep::BaseInteractor
  include Interactor

  def call
    workspace = CompanyWorkspace.find(context.company_workspace_id)
    
    # Check if we've processed recently (within 1 day for incremental updates)
    last_processed = workspace.news_pieces.maximum(:updated_at)
    if last_processed && last_processed > 1.day.ago
      Rails.logger.info "News for #{workspace.company_symbol} are up to date"
      return
    end
    
    # Fetch news data
    fetch_fmp_articles(workspace)
    fetch_general_news(workspace)
    
    Rails.logger.info "Completed processing news for #{workspace.company_symbol}"
  end

  private

  def fetch_fmp_articles(workspace)
    context.url = "https://financialmodelingprep.com/stable/fmp-articles?page=0&limit=50"
    
    # Call API directly
    response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    # Filter articles related to the company symbol
    company_articles = context.response_result.select do |article|
      article['title']&.include?(workspace.company_symbol) ||
      article['content']&.include?(workspace.company_symbol) ||
      article['title']&.include?(workspace.company_name) ||
      article['content']&.include?(workspace.company_name)
    end
    
    company_articles.each do |article|
      # Skip if we already have this article
      next if NewsPiece.exists?(
        company_workspace: workspace,
        url: article['url']
      )
      
      summary = generate_news_summary(article['content'], workspace.company_symbol) if article['content']
      
      NewsPiece.create!(
        company_workspace: workspace,
        title: article['title'],
        url: article['url'],
        published_date: DateTime.parse(article['date']),
        author: article['author'],
        content: article['content'],
        summary: summary
      )
    end
    
    Rails.logger.info "Stored #{company_articles.length} FMP articles for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing FMP articles for #{workspace.company_symbol}: #{e.message}"
  end

  def fetch_general_news(workspace)
    sleep 0.5 # Rate limiting
    
    context.url = "https://financialmodelingprep.com/stable/news/general-latest?page=0&limit=100"
    
    # Call API directly
    response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
    context.response_result = JSON.parse(response.body)
    
    return unless context.response_result.is_a?(Array) && !context.response_result.empty?
    
    # Filter news related to the company symbol
    company_news = context.response_result.select do |news|
      news['title']&.include?(workspace.company_symbol) ||
      news['text']&.include?(workspace.company_symbol) ||
      news['title']&.include?(workspace.company_name) ||
      news['text']&.include?(workspace.company_name)
    end
    
    company_news.each do |news|
      # Skip if we already have this news
      next if NewsPiece.exists?(
        company_workspace: workspace,
        url: news['url']
      )
      
      summary = generate_news_summary(news['text'], workspace.company_symbol) if news['text']
      
      NewsPiece.create!(
        company_workspace: workspace,
        title: news['title'],
        url: news['url'],
        published_date: DateTime.parse(news['publishedDate']),
        author: news['site'],
        content: news['text'],
        summary: summary
      )
    end
    
    Rails.logger.info "Stored #{company_news.length} general news articles for #{workspace.company_symbol}"
    
  rescue => e
    Rails.logger.error "Error processing general news for #{workspace.company_symbol}: #{e.message}"
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
        max_tokens: 1000,
        temperature: 0.3
      )
      
      response.choices.first.message.content
      
    rescue => e
      Rails.logger.error "OpenAI API error: #{e.message}"
      nil
    end
  end
end