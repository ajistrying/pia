class CreateKeyRatios < ActiveRecord::Migration[7.1]
  def change
    create_table :key_ratios do |t|
      t.references :company_workspace, null: false, foreign_key: true

      t.timestamps
    end
  end
end
