class CreateAnalystRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :analyst_ratings do |t|
      t.references :company_workspace, null: false, foreign_key: true
      t.string :rating_agency
      t.string :rating
      t.decimal :price_target
      t.date :target_date
      t.string :analyst_name
      t.text :notes
      t.date :created_date

      t.timestamps
    end
  end
end
