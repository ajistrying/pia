# == Schema Information
#
# Table name: company_workspaces
#
#  id             :bigint           not null, primary key
#  company_symbol :string
#  company_name   :string
#  description    :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class CompanyWorkspace < ApplicationRecord
  has_many :sec_filings, dependent: :destroy
  has_many :earnings_calls, dependent: :destroy
  has_many :key_ratios, dependent: :destroy
  has_many :financial_statements, dependent: :destroy
  has_many :news_pieces, dependent: :destroy
  has_many :research_reports, dependent: :destroy
end
