class AddProcessingFieldsToCompanyWorkspace < ActiveRecord::Migration[7.1]
  def change
    add_column :company_workspaces, :last_update_started_at, :datetime
    add_column :company_workspaces, :processing_status, :string
    add_column :company_workspaces, :progress_percentage, :integer
  end
end
