# == Schema Information
#
# Table name: analyst_ratings
#
#  id                   :bigint           not null, primary key
#  analyst_name         :string
#  created_date         :date
#  notes                :text
#  price_target         :decimal(, )
#  rating               :string
#  rating_agency        :string
#  target_date          :date
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_analyst_ratings_on_company_workspace_id  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
require 'rails_helper'

RSpec.describe AnalystRating, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
