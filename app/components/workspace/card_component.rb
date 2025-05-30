# frozen_string_literal: true

class Workspace::CardComponent < ViewComponent::Base
  def initialize(workspace:)
    @workspace = workspace
  end
end
