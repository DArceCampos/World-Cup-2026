module Api
  module V1
    # TeamsController maneja el CRUD de selecciones participantes.
    # Su función es permitir crear, leer, actualizar y eliminar equipos,
    # además de restaurar los nombres y códigos originales de los 48 países.
    class TeamsController < ApplicationController
      before_action :set_team, only: %i[show update destroy]

      # GET /api/v1/teams
      # Devuelve los 48 equipos ordenados alfabéticamente con todas sus estadísticas.
      # includes(:group) evita N+1 queries al acceder a team.group.name.
      def index
        teams = Team.includes(:group).order(:name)
        render_data(teams.map { |t| TeamSerializer.new(t).as_json })
      end

      # GET /api/v1/teams/:id
      # Devuelve el detalle completo de un equipo con sus estadísticas.
      def show
        render_data(TeamSerializer.new(@team).as_json)
      end

      # POST /api/v1/teams
      # Crea un nuevo equipo. Si el grupo ya tiene 4 equipos, la validación
      # group_not_full del modelo lanza RecordInvalid → respuesta 422.
      def create
        team = Team.new(team_params)
        team.save!
        render_data(TeamSerializer.new(team).as_json, status: :created)
      end

      # PUT/PATCH /api/v1/teams/:id
      # Actualiza el nombre o código del equipo. Se usa desde el panel admin
      # cuando el usuario edita un equipo manualmente.
      def update
        @team.update!(team_params)
        render_data(TeamSerializer.new(@team).as_json)
      end

      # Esta constante tiene los nombres y códigos FIFA originales de los 48
      # equipos, organizados por grupo. Es una copia exacta de los datos del seed.
      # Se usa en reset_names para saber a qué valores restaurar cada equipo.
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
      # Este método lo que hace es restaurar todos los equipos a sus nombres y
      # códigos originales. Busca cada grupo por letra, ordena sus equipos por ID
      # (el mismo orden en que fueron creados en el seed), y los actualiza uno a uno.
      # Se usa el orden por ID porque si un equipo fue renombrado, no se puede
      # buscar por nombre original — podría haber cambiado.
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
      # Este método elimina un equipo solo si no tiene partidos registrados.
      # Si tiene partidos, responde 409 CONFLICT porque eliminar el equipo
      # dejaría esos partidos sin uno de sus equipos — viola la integridad.
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

      # Solo permite name, code y group_id — protege contra mass assignment.
      def team_params
        params.require(:team).permit(:name, :code, :group_id)
      end
    end
  end
end
