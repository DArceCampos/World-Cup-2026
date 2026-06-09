module Api
  module V1
    # SimulationsController — genera resultados automáticos: un partido, un
    # grupo, todos los grupos o el torneo completo. Delega en MatchSimulator.
    class SimulationsController < ApplicationController
      # POST /api/v1/simulations/match/:id
      def match
        render_matches([MatchSimulator.match(Match.find(params[:id]))])
      end

      # POST /api/v1/simulations/group/:id
      def group
        render_matches(MatchSimulator.group(Group.find(params[:id])))
      end

      # POST /api/v1/simulations/groups
      def groups
        render_matches(MatchSimulator.all_groups(current_tournament))
      end

      # POST /api/v1/simulations/tournament
      def tournament
        simulated = MatchSimulator.tournament(current_tournament)
        render_data({
          status: current_tournament.reload.status,
          champion: TeamSerializer.brief(current_tournament.champion),
          simulated_count: simulated.size,
          simulated: simulated.map { |m| MatchSerializer.new(m).as_json }
        })
      end

      private

      def current_tournament
        Tournament.first || raise(ActiveRecord::RecordNotFound, "No hay torneo creado")
      end

      def render_matches(matches)
        render_data({
          simulated_count: matches.size,
          simulated: matches.map { |m| MatchSerializer.new(m).as_json }
        })
      end
    end
  end
end
