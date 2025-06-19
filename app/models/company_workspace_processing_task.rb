# == Schema Information
#
# Table name: company_workspace_processing_tasks
#
#  id                   :bigint           not null, primary key
#  started_at           :datetime
#  task_type            :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  idx_on_company_workspace_id_e31b0c615a  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
class CompanyWorkspaceProcessingTask < ApplicationRecord
  belongs_to :company_workspace
  
  REFRESH_TASK_TYPES = %w[
    news_refresh
    financial_statements_refresh
    sec_filings_refresh
    financial_ratios_refresh
  ].freeze
  
  validates :task_type, presence: true, inclusion: { in: REFRESH_TASK_TYPES }
  validates :started_at, presence: true
  validates :task_type, uniqueness: { scope: :company_workspace_id }
  
  scope :stale, -> { where('started_at < ?', 10.minutes.ago) }

  def stale?
    started_at < 10.minutes.ago
  end
end
