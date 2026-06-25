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

      ORIGINAL_TEAMS_BY_GROUP = {
        "A" => [["México","MEX"],["Sudáfrica","RSA"],["República de Corea","KOR"],["Chequia","CZE"]],
        "B" => [["Canadá","CAN"],["Bosnia y Herzegovina","BIH"],["Catar","QAT"],["Suiza","SUI"]],
        "C" => [["Brasil","BRA"],["Marruecos","MAR"],["Haití","HAI"],["Escocia","SCO"]],
        "D" => [["EE. UU.","USA"],["Paraguay","PAR"],["Australia","AUS"],["Turquía","TUR"]],
        "E" => [["Alemania","GER"],["Curazao","CUW"],["Costa de Marfil","CIV"],["Ecuador","ECU"]],
        "F" => [["Países Bajos","NED"],["Japón","JPN"],["Suecia","SWE"],["Túnez","TUN"]],
        "G" => [["Bélgica","BEL"],["Egipto","EGY"],["RI de Irán","IRN"],["Nueva Zelanda","NZL"]],
        "H" => [["España","ESP"],["Islas de Cabo Verde","CPV"],["Arabia Saudí","KSA"],["Uruguay","URU"]],
        "I" => [["Francia","FRA"],["Senegal","SEN"],["Irak","IRQ"],["Noruega","NOR"]],
        "J" => [["Argentina","ARG"],["Argelia","ALG"],["Austria","AUT"],["Jordania","JOR"]],
        "K" => [["Portugal","POR"],["RD Congo","COD"],["Uzbekistán","UZB"],["Colombia","COL"]],
        "L" => [["Inglaterra","ENG"],["Croacia","CRO"],["Ghana","GHA"],["Panamá","PAN"]]
      }.freeze

      # POST /api/v1/teams/reset_names
      def reset_names
        ORIGINAL_TEAMS_BY_GROUP.each do |group_letter, originals|
          group = Group.find_by(name: group_letter)
          next unless group
          teams = group.teams.order(:id)
          teams.each_with_index do |team, i|
            original = originals[i]
            next unless original
            team.update!(name: original[0], code: original[1])
          end
        end
        render_data({ reset: true })
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
        params.require(:team).permit(:name, :code, :group_id)
      end
    end
  end
end
