module Api
  module V1
    # MatchesController lista partidos y registra sus resultados.
    # Su función es ser el punto de entrada para todo lo relacionado con
    # resultados de partidos. Eso sí, este controlador no sabe cómo se
    # calculan estadísticas ni cómo se avanza el bracket — delega eso
    # en MatchResultRecorder y KnockoutAdvancer respectivamente.
    class MatchesController < ApplicationController
      # GET /api/v1/matches
      # Este método lista todos los partidos con filtros opcionales por fase
      # y estado. Por ejemplo, ?phase=group&status=scheduled devuelve solo
      # los partidos de grupo que aún no se han jugado.
      def index
        matches = Match.all
        matches = matches.where(phase: params[:phase])   if params[:phase].present?
        matches = matches.where(status: params[:status]) if params[:status].present?
        matches = matches.order(:phase, :round_number, :id)
        render_data(matches.map { |m| MatchSerializer.new(m).as_json })
      end

      # PATCH /api/v1/matches/:id/result
      # Este método es el más importante del controlador. Lo que hace es:
      # 1. Buscar el partido por ID.
      # 2. Registrar el resultado delegando en MatchResultRecorder (que también
      #    actualiza las estadísticas de los equipos si es partido de grupos).
      # 3. Si es un partido de eliminatoria, intenta avanzar el bracket con
      #    KnockoutAdvancer.advance!. Si ya existe la siguiente ronda (advance!
      #    retorna false), propaga el cambio de ganador al partido correspondiente.
      # 4. Si la final quedó jugada, marca el torneo como finalizado.
      def result
        match = Match.find(params[:id])
        MatchResultRecorder.new(match, result_params).call

        next_created = false
        if match.knockout?
          advancer = KnockoutAdvancer.new(match.tournament)
          next_created = advancer.advance!
          # Si la ronda siguiente ya existía, actualizar el equipo que cambió.
          advancer.propagate_winner_change(match) unless next_created
          mark_finished_if_needed(match.tournament)
        end

        render_data({
          match:              MatchSerializer.new(match).as_json,
          standings_updated:  match.group_phase?,   # true si se actualizaron posiciones
          next_match_created: next_created           # true si se creó la siguiente ronda
        })
      end

      private

      # Solo permite los campos de marcador — nada más puede venir del cliente.
      def result_params
        params.permit(:home_goals, :away_goals, :home_extra_goals,
                      :away_extra_goals, :home_penalties, :away_penalties)
      end

      # Si la final ya se jugó, el torneo terminó. Se verifica aquí porque
      # registrar el resultado de la final no llama a advance! — la final es
      # la última ronda y no hay siguiente fase que crear.
      def mark_finished_if_needed(tournament)
        final = tournament.final_match
        tournament.update!(status: "finished") if final&.played?
      end
    end
  end
end
