class AddWorkspaceFieldsForInitializationAndUpdate < ActiveRecord::Migration[7.1]
  def change
    add_column :company_workspaces, :last_successful_update, :datetime
    add_column :company_workspaces, :initialized_at, :datetime
  end
end
