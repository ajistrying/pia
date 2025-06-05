# == Schema Information
#
# Table name: sec_filings
#
#  id                   :bigint           not null, primary key
#  cik                  :string
#  filing_date          :date
#  final_link           :string
#  form_type            :string
#  processed_at         :datetime
#  sec_link             :string
#  summary              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_sec_filings_on_company_workspace_id  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
class SecFiling < ApplicationRecord
  belongs_to :company_workspace
end
