# == Schema Information
#
# Table name: company_workspaces
#
#  id                     :bigint           not null, primary key
#  company_name           :string
#  company_symbol         :string
#  description            :text
#  initialized_at         :datetime
#  last_successful_update :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require 'rails_helper'

RSpec.describe CompanyWorkspace, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
