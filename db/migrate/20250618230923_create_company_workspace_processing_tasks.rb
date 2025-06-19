class CreateCompanyWorkspaceProcessingTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :company_workspace_processing_tasks do |t|
      t.references :company_workspace, null: false, foreign_key: true
      t.string :task_type
      t.datetime :started_at

      t.timestamps
    end
  end
end
