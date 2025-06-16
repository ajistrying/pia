# == Schema Information
#
# Table name: key_ratios
#
#  id                   :bigint           not null, primary key
#  period               :string
#  quarter              :integer
#  ratio_name           :string
#  ratio_value          :decimal(, )
#  ttm                  :boolean
#  year                 :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_workspace_id :bigint           not null
#
# Indexes
#
#  index_key_ratios_on_company_workspace_id  (company_workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_workspace_id => company_workspaces.id)
#
require 'rails_helper'

RSpec.describe KeyRatio, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
