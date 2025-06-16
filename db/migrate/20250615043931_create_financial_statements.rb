class CreateFinancialStatements < ActiveRecord::Migration[7.1]
  def change
    create_table :financial_statements do |t|
      t.references :company_workspace, null: false, foreign_key: true
      t.string :statement_type
      t.string :period
      t.integer :year
      t.integer :quarter
      t.decimal :revenue
      t.decimal :gross_profit
      t.decimal :operating_income
      t.decimal :net_income
      t.decimal :total_assets
      t.decimal :total_debt
      t.decimal :shareholders_equity
      t.decimal :operating_cash_flow
      t.decimal :free_cash_flow
      t.decimal :eps

      t.timestamps
    end
  end
end
