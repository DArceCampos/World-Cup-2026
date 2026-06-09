module Api
  module V1
    # GroupsController — CRUD de grupos y consulta de tablas de posiciones.
    class GroupsController < ApplicationController
      before_action :set_group, only: %i[show update destroy]

      # GET /api/v1/groups
      def index
        groups = Group.includes(:teams).order(:name)
        render_data(groups.map { |g| GroupSerializer.new(g).as_json })
      end

      # GET /api/v1/groups/:id
      def show
        render_data(GroupSerializer.new(@group, include_matches: true).as_json)
      end

      # POST /api/v1/groups
      def create
        group = Group.new(group_params)
        group.tournament ||= current_tournament
        group.save!
        render_data(GroupSerializer.new(group).as_json, status: :created)
      end

      # PUT/PATCH /api/v1/groups/:id
      def update
        @group.update!(group_params)
        render_data(GroupSerializer.new(@group).as_json)
      end

      # DELETE /api/v1/groups/:id
      def destroy
        @group.destroy!
        head :no_content
      end

      private

      def set_group
        @group = Group.find(params[:id])
      end

      def group_params
        params.require(:group).permit(:name, :tournament_id)
      end

      def current_tournament
        Tournament.first || Tournament.create!(name: "Copa Mundial FIFA 2026", status: "setup")
      end
    end
  end
end
