# == Schema Information
#
# Table name: earnings_calls
#
#  id                   :bigint           not null, primary key
#  company_workspace_id :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class EarningsCall < ApplicationRecord
  belongs_to :company_workspace
end
