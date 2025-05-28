# == Schema Information
#
# Table name: news_pieces
#
#  id                   :bigint           not null, primary key
#  company_workspace_id :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require 'rails_helper'

RSpec.describe NewsPiece, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
