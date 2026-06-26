# DashboardController es la pantalla principal del torneo. Su función es mostrar
# un resumen de estado: en qué fase está el torneo, cuántos partidos se jugaron,
# cuántos faltan, el porcentaje de avance, y quiénes son los tres primeros si
# el torneo ya terminó. Eso sí, si el backend no responde, el rescue garantiza
# que la vista siempre tenga variables válidas y no explote con un nil error.
class DashboardController < ApplicationController
  def index
    tournament  = ApiClient.tournament
    all_matches = ApiClient.matches

    total   = all_matches.size
    played  = all_matches.count { |m| m["status"] == "played" }
    pending = total - played
    # El porcentaje se calcula solo si hay partidos para evitar división por cero.
    pct     = total > 0 ? (played.to_f / total * 100).round : 0

    # Este hash es lo que la vista recibe para pintar la barra de progreso,
    # el badge de fase y los mensajes de estado.
    @tournament = {
      status:   tournament["status"],
      phase:    phase_display(tournament["status"]),
      played:   played,
      total:    total,
      pending:  pending,
      pct:      pct,
      finished: tournament["status"] == "finished"
    }

    # team_brief devuelve nil si el torneo aún no tiene campeón/subcampeón/tercero,
    # y la vista maneja ese nil mostrando "POR DEFINIR".
    @champion  = team_brief(tournament["champion"])
    @runner_up = team_brief(tournament["runner_up"])
    @third     = team_brief(tournament["third_place"])
  rescue StandardError
    # Si el backend no está disponible, el dashboard muestra un estado de error
    # en vez de lanzar una excepción 500 al usuario.
    @tournament = { status: "error", phase: "BACKEND NO DISPONIBLE", played: 0,
                    total: 0, pending: 0, pct: 0, finished: false }
    @champion = @runner_up = @third = nil
  end
end
