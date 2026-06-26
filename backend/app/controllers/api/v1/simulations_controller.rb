module Api
  module V1
    # SimulationsController genera resultados automáticos para los partidos.
    # Su función es ofrecer cuatro niveles de simulación: un partido, un grupo,
    # todos los grupos, o el torneo completo. Eso sí, este controlador no
    # genera ningún resultado por sí mismo — delega completamente en MatchSimulator.
    class SimulationsController < ApplicationController
      # POST /api/v1/simulations/match/:id
      # Simula un único partido específico. Si ya está jugado, MatchSimulator
      # lo retorna sin cambios (es idempotente).
      def match
        render_matches([MatchSimulator.match(Match.find(params[:id]))])
      end

      # POST /api/v1/simulations/group/:id
      # Simula todos los partidos pendientes de un grupo específico.
      def group
        render_matches(MatchSimulator.group(Group.find(params[:id])))
      end

      # POST /api/v1/simulations/groups
      # Simula todos los partidos pendientes de la fase de grupos completa.
      # Es la acción del botón "Simular fase grupos" del panel admin.
      def groups
        render_matches(MatchSimulator.all_groups(current_tournament))
      end

      # POST /api/v1/simulations/tournament
      # Este método simula el torneo completo: grupos, bracket y todas las rondas
      # hasta que haya un campeón. La respuesta incluye el campeón final y el
      # conteo total de partidos simulados. Es la acción del botón
      # "Simular torneo completo" del panel admin.
      def tournament
        simulated = MatchSimulator.tournament(current_tournament)
        render_data({
          status:          current_tournament.reload.status,
          champion:        TeamSerializer.brief(current_tournament.champion),
          simulated_count: simulated.size,
          simulated:       simulated.map { |m| MatchSerializer.new(m).as_json }
        })
      end

      private

      # En SimulationsController se lanza un error explícito si no hay torneo,
      # porque simular sin torneo no tiene ningún sentido (a diferencia de otros
      # controladores donde se crea uno vacío como fallback).
      def current_tournament
        Tournament.first || raise(ActiveRecord::RecordNotFound, "No hay torneo creado")
      end

      # Este método privado arma la respuesta estándar para las simulaciones
      # de match, group y groups — siempre devuelve el conteo y los partidos.
      def render_matches(matches)
        render_data({
          simulated_count: matches.size,
          simulated:       matches.map { |m| MatchSerializer.new(m).as_json }
        })
      end
    end
  end
end
