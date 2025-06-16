# == Schema Information
#
# Table name: workspace_task_completions
#
#  id                   :bigint           not null, primary key
#  completed_at         :datetime         not null
#  task_type            :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_workspace_task_completions_on_company_workspace_id  (company_workspace_id)
#  unique_workspace_task_completion                          (company_workspace_id,task_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
class WorkspaceTaskCompletion < ApplicationRecord
  belongs_to :company_workspace
  
  validates :task_type, presence: true, 
            inclusion: { in: WorkspaceUpdateTracker::TASK_TYPES }
  validates :completed_at, presence: true
  validates :task_type, uniqueness: { scope: :company_workspace_id }
end 
