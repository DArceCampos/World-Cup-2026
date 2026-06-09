module Api
  module V1
    # TeamsController — CRUD de selecciones participantes.
    class TeamsController < ApplicationController
      before_action :set_team, only: %i[show update destroy]

      # GET /api/v1/teams
      def index
        teams = Team.includes(:group).order(:name)
        render_data(teams.map { |t| TeamSerializer.new(t).as_json })
      end

      # GET /api/v1/teams/:id
      def show
        render_data(TeamSerializer.new(@team).as_json)
      end

      # POST /api/v1/teams
      def create
        team = Team.new(team_params)
        team.save!
        render_data(TeamSerializer.new(team).as_json, status: :created)
      end

      # PUT/PATCH /api/v1/teams/:id
      def update
        @team.update!(team_params)
        render_data(TeamSerializer.new(@team).as_json)
      end

      # DELETE /api/v1/teams/:id
      def destroy
        if @team.matches.exists?
          return render_error("CONFLICT", "No se puede eliminar un equipo con partidos registrados", :conflict)
        end

        @team.destroy!
        head :no_content
      end

      private

      def set_team
        @team = Team.find(params[:id])
      end

      def team_params
        params.require(:team).permit(:name, :group_id)
      end
    end
  end
end
