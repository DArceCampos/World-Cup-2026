class GroupsController < ApplicationController
  def index
    @groups = ApiClient.groups.map { |g| build_group(g) }
  rescue StandardError
    @groups = []
  end

  def show
    api_group = ApiClient.group(params[:id])
    redirect_to groups_path and return unless api_group
    @group = build_group(api_group)
  rescue StandardError
    redirect_to groups_path
  end
end
