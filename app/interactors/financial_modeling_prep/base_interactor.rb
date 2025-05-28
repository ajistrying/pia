class FinancialModelingPrep::BaseInteractor < BaseInteractor
  required_context :url

  def call
    begin
      response = Faraday.get("#{context.url}&apikey=#{ENV['FINANCIAL_MODELING_PREP_API_KEY']}")
      context.response_result = JSON.parse(response.body)
    rescue Faraday::ClientError => e
      context.fail!(calling_interactor: self.class.name, error: { message: " A 4xx client error occurred", body: e.response_body, status: e.response_status, code: e.response_code, })
    rescue Faraday::ServerError => e
      context.fail!(calling_interactor: self.class.name, error: { message: " A 5xx server error occurred", body: e.response_body, status: e.response_status, code: e.response_code, })
    rescue => e
      context.fail!(calling_interactor: self.class.name, error: { message: " An error occurred"})
    end
  end
end