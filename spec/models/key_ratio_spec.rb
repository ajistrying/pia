# == Schema Information
#
# Table name: key_ratios
#
#  id                   :bigint           not null, primary key
#  company_workspace_id :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
require 'rails_helper'

RSpec.describe KeyRatio, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
