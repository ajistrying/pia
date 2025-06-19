class CompanyWorkspacesController < ApplicationController
  before_action :set_workspace, only: [:show, :workspace_content, :financial_ratios_tab, :financial_statements_tab, :refresh_sec_filings, :refresh_financial_ratios, :refresh_news_sentiment, :refresh_financial_statements]
  before_action :ensure_workspace_processing, only: [:show]

  def create
    @workspace = CompanyWorkspace.create(
      company_symbol: params[:company_symbol],
      company_name: params[:company_name]
    )
    redirect_to company_workspace_path(@workspace)
  end

  def show
    # The view will handle displaying loading or content based on workspace state
  end

  def workspace_content
    @tab = params[:tab] || 'overview'
    
    # Handle AJAX tab requests
    if request.xhr?
      Rails.logger.info "XHR request received"
      case @tab
      when 'overview'
        render partial: 'tab_overview', locals: { workspace: @workspace }
      when 'sec-filings'
        render partial: 'tab_sec_filings', locals: { workspace: @workspace }
      when 'financial-ratios'
        @ratio_tab = params[:ratio_tab] || 'profitability'
        render partial: 'tab_financial_ratios', locals: { workspace: @workspace, active_tab: @ratio_tab }
      when 'news-sentiment'
        if @workspace.refresh_in_progress?('news')
          render partial: 'tab_news_sentiment_loading'
        else
          render partial: 'tab_news_sentiment', locals: { workspace: @workspace }
        end
      when 'financial-statements'
        render partial: 'tab_financial_statements', locals: { workspace: @workspace }
      else
        render partial: 'tab_overview', locals: { workspace: @workspace }
      end
    else
      Rails.logger.info "Workspace is up to date: #{@workspace.up_to_date?}"
      # This action is called by Turbo Frame to load the actual content
      if @workspace.up_to_date?
        Rails.logger.info "Workspace is up to date"
        render partial: "workspace_content", locals: { workspace: @workspace }
      else
        # Show loading while job processes
        render partial: "company_workspaces/loading_skeleton_component"
      end
    end
  end

  def financial_ratios_tab
    @ratio_tab = params[:ratio_tab] || 'profitability'
    respond_to do |format|
      format.html { render partial: 'tab_financial_ratios', locals: { workspace: @workspace, active_tab: @ratio_tab } }
    end
  end

  def financial_statements_tab
    @statement_tab = params[:statement_tab] || 'income'
    respond_to do |format|
      format.html { render partial: 'tab_financial_statements', locals: { workspace: @workspace, active_tab: @statement_tab } }
    end
  end

  # Manual refresh actions
  def refresh_sec_filings
    # TODO: Call your SEC filings interactor here
    # Example: FinancialModelingPrep::ProcessSecFilings.call(company_symbol: @workspace.company_symbol, workspace: @workspace)
    
    head :ok
  end

  def refresh_financial_ratios
    # TODO: Call your financial ratios interactor here
    # Example: FinancialModelingPrep::ProcessKeyRatios.call(company_symbol: @workspace.company_symbol, workspace: @workspace)
    
    head :ok
  end

  def refresh_news_sentiment
    Rails.logger.info "News & sentiment refresh initiated"
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "workspace_#{@workspace.id}",
      target: "news-section",
      partial: "company_workspaces/tab_news_sentiment_loading"
    )

    processing_task = @workspace.refresh_in_progress?("news_refresh")

    if processing_task
      Rails.logger "A news refresh is already underway"
      head :ok
    end

    RefreshNewsJob.perform_later(@workspace.id)
    
    head :ok
  end

  def refresh_financial_statements
    # TODO: Call your financial statements interactor here
    # Example: FinancialModelingPrep::ProcessFinancialStatements.call(company_symbol: @workspace.company_symbol, workspace: @workspace)
    
    head :ok
  end

  private

  def set_workspace
    @workspace = CompanyWorkspace.find_by(id: params[:id])
    redirect_to root_path unless @workspace
  end

  def ensure_workspace_processing
    return if @workspace.up_to_date?

    # Queue the appropriate job
    if @workspace.initialized_at.nil?
      InitializeWorkspaceJob.perform_later(@workspace.id)
    else
      ParallelWorkspaceUpdateJob.perform_later(@workspace.id)
    end
  end
end