# == Schema Information
#
# Table name: company_workspaces
#
#  id                     :bigint           not null, primary key
#  company_name           :string
#  company_symbol         :string
#  description            :text
#  initialized_at         :datetime
#  last_successful_update :datetime
#  last_update_started_at :datetime
#  processing_status      :string
#  progress_percentage    :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_company_workspaces_on_company_symbol_and_company_name  (company_symbol,company_name) UNIQUE
#
class CompanyWorkspace < ApplicationRecord
  has_many :sec_filings, dependent: :destroy
  has_many :earnings_calls, dependent: :destroy
  has_many :key_ratios, dependent: :destroy
  has_many :analyst_ratings, dependent: :destroy
  has_many :news_pieces, dependent: :destroy
  has_many :financial_statements, dependent: :destroy
  has_many :workspace_task_completions, dependent: :destroy
  has_many :company_workspace_processing_tasks, dependent: :destroy

  def up_to_date?
    initialized_at.present? && last_successful_update && last_successful_update > 2.days.ago
  end
  
  def refresh_in_progress?(task_type)
    company_workspace_processing_tasks.exists?(task_type: "#{task_type}")
  end
  
  def active_refreshes
    company_workspace_processing_tasks.pluck(:task_type).map { |type| type.gsub('_refresh', '') }
  end
end
