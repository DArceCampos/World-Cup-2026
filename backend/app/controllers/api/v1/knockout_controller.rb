module Api
  module V1
    # KnockoutController expone el bracket eliminatorio y la lista de clasificados.
    # Su función es dar al frontend toda la información necesaria para mostrar
    # el bracket visual y saber quiénes avanzaron desde la fase de grupos.
    class KnockoutController < ApplicationController
      # Orden en que se presentan las fases del bracket. Es importante mantener
      # este orden para que el frontend pueda renderizar las columnas correctamente.
      PHASE_ORDER = %w[r32 r16 qf sf 3rd final].freeze

      # GET /api/v1/knockout/bracket
      # Este método lo que hace es devolver todas las rondas del bracket agrupadas
      # por fase, con sus partidos ordenados por round_number. Las fases vacías
      # (que todavía no se han generado) se filtran con .compact para no incluir
      # nil en la respuesta.
      def bracket
        tournament = current_tournament
        rounds = PHASE_ORDER.map do |phase|
          matches = tournament.matches.where(phase: phase).order(:round_number)
          # Si esta fase no tiene partidos todavía, la saltamos con next.
          next if matches.empty?

          {
            phase:   phase,
            matches: matches.map { |m| MatchSerializer.new(m).as_json }
          }
        end.compact

        render_data({ rounds: rounds })
      end

      # GET /api/v1/knockout/qualifiers
      # Este método devuelve los 32 clasificados a dieciseisavos:
      # - 24 directos: el primero y segundo de cada uno de los 12 grupos.
      # - 8 mejores terceros: calculados por Tournament#best_third_places.
      # Se usa desde el panel admin para verificar quiénes clasificaron antes
      # de construir el bracket.
      def qualifiers
        tournament = current_tournament

        # Los 24 directos: primero y segundo de cada grupo, con su posición.
        from_groups = tournament.groups.order(:name).flat_map do |group|
          group.qualified_teams.each_with_index.map do |team, idx|
            { team: TeamSerializer.brief(team), group: group.name, position: idx + 1 }
          end
        end

        # Los 8 mejores terceros con sus estadísticas de desempate visibles.
        best_thirds = tournament.best_third_places.map do |team|
          {
            team:            TeamSerializer.brief(team),
            group:           team.group.name,
            points:          team.points,
            goal_difference: team.goal_difference,
            goals_for:       team.goals_for
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
