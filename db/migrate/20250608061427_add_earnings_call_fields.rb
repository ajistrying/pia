class AddEarningsCallFields < ActiveRecord::Migration[7.1]
  def change
    add_column :earnings_calls, :year, :integer
    add_column :earnings_calls, :quarter, :string
    add_column :earnings_calls, :transcript, :text
    add_column :earnings_calls, :summary, :text
  end
end
