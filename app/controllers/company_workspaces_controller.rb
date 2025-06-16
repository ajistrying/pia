class CompanyWorkspacesController < ApplicationController
  before_action :set_workspace, only: [:show, :workspace_content]
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
    # This action is called by Turbo Frame to load the actual content
    if @workspace.up_to_date?
      render partial: "workspace_content", locals: { workspace: @workspace }
    else
      # Show loading while job processes
      render partial: "company_workspaces/loading_skeleton_component"
    end
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