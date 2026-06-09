module Api
  module V1
    # KnockoutController — consultas de la fase eliminatoria: el bracket
    # completo y la lista de clasificados a dieciseisavos.
    class KnockoutController < ApplicationController
      # Orden y etiquetas legibles de las fases eliminatorias.
      PHASE_ORDER = %w[r32 r16 qf sf 3rd final].freeze

      # GET /api/v1/knockout/bracket
      def bracket
        tournament = current_tournament
        rounds = PHASE_ORDER.map do |phase|
          matches = tournament.matches.where(phase: phase).order(:round_number)
          next if matches.empty?

          {
            phase: phase,
            matches: matches.map { |m| MatchSerializer.new(m).as_json }
          }
        end.compact

        render_data({ rounds: rounds })
      end

      # GET /api/v1/knockout/qualifiers
      # 24 directos (1° y 2° de cada grupo) + 8 mejores terceros.
      def qualifiers
        tournament = current_tournament

        from_groups = tournament.groups.order(:name).flat_map do |group|
          group.qualified_teams.each_with_index.map do |team, idx|
            { team: TeamSerializer.brief(team), group: group.name, position: idx + 1 }
          end
        end

        best_thirds = tournament.best_third_places.map do |team|
          {
            team: TeamSerializer.brief(team),
            group: team.group.name,
            points: team.points,
            goal_difference: team.goal_difference,
            goals_for: team.goals_for
          }
        end

        render_data({ from_groups: from_groups, best_thirds: best_thirds })
      end

      private

      def current_tournament
        Tournament.first || Tournament.create!(name: "Copa Mundial FIFA 2026", status: "setup")
      end
    end
  end
end
