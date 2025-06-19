class RefreshNewsJob < ApplicationJob
  queue_as :default

  def perform(workspace_id)
    workspace = CompanyWorkspace.find(workspace_id)
    
    begin
      processing_task = workspace.company_workspace_processing_tasks.create!(task_type: "news_refresh", started_at: DateTime.now)

      result = FinancialModelingPrep::RefreshNews.call(workspace_id: workspace_id)
      
      if result.success?      
        Rails.logger.info "Broadcasting news update for workspace #{workspace_id}"
        
        Turbo::StreamsChannel.broadcast_replace_to(
          "workspace_#{workspace.id}",
          target: "news-section",
          partial: "company_workspaces/tab_news_sentiment",
          locals: { workspace: workspace }
        )
        
        Rails.logger.info "Successfully broadcast news update for workspace #{workspace_id}"
      else
        Rails.logger.error "Error in RefreshNewsJob for workspace #{workspace_id}: #{result.message}"

        Turbo::StreamsChannel.broadcast_replace_to(
          "workspace_#{workspace_id}",
          target: "news-section",
          partial: "company_workspaces/tab_news_sentiment_error",
          locals: { workspace: workspace, error: result.message }
        )
      end
      
    rescue => e
      Rails.logger.error "Error in RefreshNewsJob for workspace #{workspace_id}: #{e.message}"
      
      Turbo::StreamsChannel.broadcast_replace_to(
        "workspace_#{workspace.id}",
        target: "news-section",
        partial: "company_workspaces/tab_news_sentiment_error",
        locals: { workspace: workspace, error: e.message }
      )
    ensure
      processing_task&.destroy
    end
  end
end