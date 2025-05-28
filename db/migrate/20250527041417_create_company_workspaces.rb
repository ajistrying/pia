class CreateCompanyWorkspaces < ActiveRecord::Migration[7.1]
  def change
    create_table :company_workspaces do |t|
      t.string :company_symbol
      t.string :company_name
      t.text :description

      t.timestamps
    end
  end
end
