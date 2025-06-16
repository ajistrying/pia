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
#  last_update_started_at :datetime
#  processing_status      :string
#  progress_percentage    :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_company_workspaces_on_company_symbol_and_company_name  (company_symbol,company_name) UNIQUE
#
require 'rails_helper'

RSpec.describe CompanyWorkspace, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
