class AddFieldsToNewsPieces < ActiveRecord::Migration[7.1]
  def change
    add_column :news_pieces, :title, :string
    add_column :news_pieces, :url, :string
    add_column :news_pieces, :published_date, :datetime
    add_column :news_pieces, :author, :string
    add_column :news_pieces, :content, :text
    add_column :news_pieces, :summary, :text
  end
end
