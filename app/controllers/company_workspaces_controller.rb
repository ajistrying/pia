class CompanyWorkspacesController < ApplicationController
  before_action :ensure_workspace_initialized, only: [:show]

  def create
    @workspace = CompanyWorkspace.create(workspace_params)
    redirect_to company_workspace_path(@workspace)
  end

  def show
  end

  private

  def workspace_params
    params.require(:company_workspace).permit(:ticker, :company_name)
  end

  def ensure_workspace_initialized
    @workspace = CompanyWorkspace.find(params[:id])

    if @workspace.initialized_at.present?
      result = FinancialModelingPrep::UpdateWorkspace.call(workspace: @workspace)
    else
      result = FinancialModelingPrep::InitializeWorkspace.call(workspace: @workspace)
    end

    if result.failure?
      @error = result.error
    else
      @workspace = result.response_result
    end
  end
end