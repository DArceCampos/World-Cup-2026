module Api
  module V1
    # TournamentsController — expone el estado global del torneo y el avance
    # de fases. Delega toda la lógica en los servicios (Dependency Inversion).
    class TournamentsController < ApplicationController
      # GET /api/v1/tournament
      def show
        tournament = current_tournament
        render_data(tournament_payload(tournament))
      end

      # PATCH /api/v1/tournament/advance
      # Avanza la fase del torneo:
      #   - group_stage -> knockout (construye dieciseisavos)
      #   - knockout    -> crea la siguiente ronda eliminatoria
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

      def current_tournament
        Tournament.first || Tournament.create!(name: "Copa Mundial FIFA 2026", status: "setup")
      end

      # Si la final ya se jugó, marca el torneo como finalizado.
      def check_finished(tournament)
        final = tournament.final_match
        tournament.update!(status: "finished") if final&.played?
      end

      def tournament_payload(tournament)
        {
          id: tournament.id,
          name: tournament.name,
          status: tournament.status,
          champion: TeamSerializer.brief(tournament.champion),
          runner_up: TeamSerializer.brief(tournament.runner_up),
          third_place: TeamSerializer.brief(tournament.third_place)
        }
      end
    end
  end
end
