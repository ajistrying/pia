# == Schema Information
#
# Table name: earnings_calls
#
#  id                   :bigint           not null, primary key
#  quarter              :string
#  summary              :text
#  transcript           :text
#  year                 :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_earnings_calls_on_company_workspace_id  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
require 'rails_helper'

RSpec.describe EarningsCall, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
