module Api
  module V1
    # TournamentsController expone el estado global del torneo y permite avanzar
    # de fase o reiniciar. Su función es ser la puerta de entrada para saber
    # en qué punto está el torneo y quién ganó. Eso sí, este controlador no
    # contiene lógica de negocio propia — delega todo en los servicios.
    class TournamentsController < ApplicationController
      # GET /api/v1/tournament
      # Este método lo que hace es buscar el torneo y devolverlo con su estado
      # actual, incluyendo campeón, subcampeón y tercer lugar si ya terminó.
      def show
        tournament = current_tournament
        render_data(tournament_payload(tournament))
      end

      # POST /api/v1/tournament/reset_groups
      # Este método lo que hace es delegar completamente en TournamentResetter
      # para borrar todos los resultados y volver el torneo a group_stage.
      # Es la acción del botón "Reiniciar torneo" del panel admin.
      def reset_groups
        tournament = current_tournament
        TournamentResetter.new(tournament).reset_groups!
        render_data({ status: tournament.reload.status, message: "Fase de grupos reiniciada." })
      end

      # PATCH /api/v1/tournament/advance
      # Este método avanza la fase del torneo. Tiene dos comportamientos:
      # - Si está en group_stage: construye los dieciseisavos con KnockoutAdvancer.
      # - Si está en knockout: avanza a la siguiente ronda eliminatoria.
      # El mensaje de respuesta cambia según lo que ocurrió.
      def advance
        tournament = current_tournament
        advancer = KnockoutAdvancer.new(tournament)

        message =
          if tournament.group_stage?
            advancer.build_round_of_32
            "Fase de grupos cerrada. Dieciseisavos generados."
          else
            created = advancer.advance!
            check_finished(tournament)
            created ? "Siguiente ronda generada." : "No hay rondas pendientes por avanzar."
          end

        render_data({ status: tournament.reload.status, message: message })
      end

      private

      # Este método busca el torneo activo o lo crea si no existe todavía.
      # En este sistema hay un único torneo, por eso se usa Tournament.first.
      def current_tournament
        Tournament.first || Tournament.create!(name: "Copa Mundial FIFA 2026", status: "setup")
      end

      # Este método verifica si la final ya se jugó para marcar el torneo como
      # finalizado. Se llama después de advance! porque podría ser que la final
      # ya estuviera jugada antes de que alguien llame a este endpoint.
      def check_finished(tournament)
        final = tournament.final_match
        tournament.update!(status: "finished") if final&.played?
      end

      # Este método arma el hash de respuesta del torneo con todos sus campos,
      # incluyendo los tres lugares del podio (nil si todavía no hay resultados).
      def tournament_payload(tournament)
        {
          id: tournament.id,
          name: tournament.name,
          status: tournament.status,
          champion:    TeamSerializer.brief(tournament.champion),
          runner_up:   TeamSerializer.brief(tournament.runner_up),
          third_place: TeamSerializer.brief(tournament.third_place)
        }
      end
    end
  end
end
