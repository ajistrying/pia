# == Schema Information
#
# Table name: company_workspaces
#
#  id             :bigint           not null, primary key
#  company_symbol :string
#  company_name   :string
#  description    :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require 'rails_helper'

RSpec.describe CompanyWorkspace, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
