# == Schema Information
#
# Table name: news_pieces
#
#  id                   :bigint           not null, primary key
#  author               :string
#  content              :text
#  published_date       :datetime
#  summary              :text
#  title                :string
#  url                  :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_news_pieces_on_company_workspace_id  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
class NewsPiece < ApplicationRecord
  belongs_to :company_workspace
end
