# == Schema Information
#
# Table name: financial_statements
#
#  id                   :bigint           not null, primary key
#  eps                  :decimal(, )
#  free_cash_flow       :decimal(, )
#  gross_profit         :decimal(, )
#  net_income           :decimal(, )
#  operating_cash_flow  :decimal(, )
#  operating_income     :decimal(, )
#  period               :string
#  quarter              :integer
#  revenue              :decimal(, )
#  shareholders_equity  :decimal(, )
#  statement_type       :string
#  total_assets         :decimal(, )
#  total_debt           :decimal(, )
#  year                 :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_financial_statements_on_company_workspace_id  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
require 'rails_helper'

RSpec.describe FinancialStatement, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
