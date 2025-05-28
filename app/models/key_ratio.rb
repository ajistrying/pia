# == Schema Information
#
# Table name: key_ratios
#
#  id                   :bigint           not null, primary key
#  company_workspace_id :bigint           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class KeyRatio < ApplicationRecord
  belongs_to :company_workspace
end
