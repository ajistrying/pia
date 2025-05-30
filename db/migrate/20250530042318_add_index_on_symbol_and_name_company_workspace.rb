class AddIndexOnSymbolAndNameCompanyWorkspace < ActiveRecord::Migration[7.1]
  def change
    add_index :company_workspaces, [:company_symbol, :company_name], unique: true
  end
end
