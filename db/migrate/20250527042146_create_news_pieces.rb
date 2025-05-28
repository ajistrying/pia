class CreateNewsPieces < ActiveRecord::Migration[7.1]
  def change
    create_table :news_pieces do |t|
      t.references :company_workspace, null: false, foreign_key: true

      t.timestamps
    end
  end
end
