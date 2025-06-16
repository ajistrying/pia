class CreateWorkspaceTaskCompletions < ActiveRecord::Migration[7.1]
  def change
    create_table :workspace_task_completions do |t|
      t.references :company_workspace, null: false, foreign_key: true
      t.string :task_type, null: false
      t.datetime :completed_at, null: false

      t.timestamps
    end
    
    add_index :workspace_task_completions, [:company_workspace_id, :task_type], 
              unique: true, name: 'unique_workspace_task_completion'
  end
end
