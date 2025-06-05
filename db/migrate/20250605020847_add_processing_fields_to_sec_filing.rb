class AddProcessingFieldsToSecFiling < ActiveRecord::Migration[7.1]
  def change
    add_column :sec_filings, :cik, :string
    add_column :sec_filings, :filing_date, :date
    add_column :sec_filings, :form_type, :string
    add_column :sec_filings, :sec_link, :string
    add_column :sec_filings, :final_link, :string
    add_column :sec_filings, :summary, :text
    add_column :sec_filings, :processed_at, :datetime
  end
end
