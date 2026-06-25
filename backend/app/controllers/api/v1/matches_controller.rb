module Api
  module V1
    # MatchesController — lista partidos y registra resultados.
    #
    # El registro de resultados delega en MatchResultRecorder y, si el
    # partido era eliminatorio, intenta avanzar el bracket automáticamente
    # vía KnockoutAdvancer (Dependency Inversion: el controller no conoce
    # los detalles de cómo se actualizan stats ni cómo se arma la siguiente
    # ronda).
    class MatchesController < ApplicationController
      # GET /api/v1/matches  (filtros: ?phase=group, ?status=scheduled)
      def index
        matches = Match.all
        matches = matches.where(phase: params[:phase]) if params[:phase].present?
        matches = matches.where(status: params[:status]) if params[:status].present?
        matches = matches.order(:phase, :round_number, :id)
        render_data(matches.map { |m| MatchSerializer.new(m).as_json })
      end

      # PATCH /api/v1/matches/:id/result
      def result
        match = Match.find(params[:id])
        MatchResultRecorder.new(match, result_params).call

        next_created = false
        if match.knockout?
          advancer = KnockoutAdvancer.new(match.tournament)
          next_created = advancer.advance!
          advancer.propagate_winner_change(match) unless next_created
          mark_finished_if_needed(match.tournament)
        end

        render_data({
          match: MatchSerializer.new(match).as_json,
          standings_updated: match.group_phase?,
          next_match_created: next_created
        })
      end

      private

      def result_params
        params.permit(:home_goals, :away_goals, :home_extra_goals,
                      :away_extra_goals, :home_penalties, :away_penalties)
      end

      def mark_finished_if_needed(tournament)
        final = tournament.final_match
        tournament.update!(status: "finished") if final&.played?
      end
    end
  end
end
