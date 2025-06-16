class AddFieldsToKeyRatios < ActiveRecord::Migration[7.1]
  def change
    add_column :key_ratios, :ratio_name, :string
    add_column :key_ratios, :ratio_value, :decimal
    add_column :key_ratios, :period, :string
    add_column :key_ratios, :year, :integer
    add_column :key_ratios, :quarter, :integer
    add_column :key_ratios, :ttm, :boolean
  end
end
