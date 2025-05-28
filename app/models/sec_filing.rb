# == Schema Information
#
# Table name: sec_filings
#
#  id                   :bigint           not null, primary key
#  company_workspace_id :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class SecFiling < ApplicationRecord
  belongs_to :company_workspace
end
