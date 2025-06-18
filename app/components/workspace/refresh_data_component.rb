class Workspace::RefreshDataComponent < ViewComponent::Base
  def initialize(link_path:, icon:, title:, description:)
    @link_path = link_path
    @icon = icon
    @title = title
    @description = description
  end
end