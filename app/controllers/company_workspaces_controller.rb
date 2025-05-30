class CompanyWorkspacesController < ApplicationController
  before_action :ensure_up_to_date_workspace, only: [:show]

  def create
    @workspace = CompanyWorkspace.create(workspace_params)
    redirect_to company_workspace_path(@workspace)
  end

  def show
  end

  private

  def workspace_params
    params.require(:company_workspace).permit(:company_symbol, :company_name)
  end

  def ensure_up_to_date_workspace
    @workspace = CompanyWorkspace.find(params[:id])

    return if @workspace.up_to_date?

    if @workspace.initialized_at.nil?
      result = FinancialModelingPrep::InitializeWorkspace.call(workspace: @workspace)
      if result.failure?
        @error = result.error
      end
    else
      result = FinancialModelingPrep::UpdateWorkspace.call(workspace: @workspace)
      if result.failure?
        @error = result.error
      end
    end

    redirect_to company_workspace_path(@workspace), alert: @error if @error.present?
  end
end