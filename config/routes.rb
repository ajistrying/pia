require 'sidekiq/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Sidekiq Web UI (in production, you'd want to secure this with authentication)
  mount Sidekiq::Web => "/sidekiq"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  get "/", to: "company_search#index", as: :root
  get "/company_search/search", to: "company_search#search", as: :company_search_search

  resources :company_workspaces, only: [:destroy, :create, :show, :update, :edit] do
    member do
      get :workspace_content
      get :financial_ratios_tab
      
      post :pull_sec_filing
      post :pull_earnings_call
      post :pull_key_ratio
      post :pull_financial_statement
      post :pull_news_piece
      post :pull_research_report
    end
    
    resources :sec_filings, only: [:destroy] do
      member do
        get :summary
      end
    end
    resources :earnings_calls, only: [:destroy]
    resources :key_ratios, only: [:destroy]
    resources :financial_statements, only: [:destroy]
    resources :news_pieces, only: [:destroy] do
      member do
        get :summary
      end
    end
    resources :research_reports, only: [:destroy]
  end
end
