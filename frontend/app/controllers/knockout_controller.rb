# KnockoutController maneja la vista del bracket eliminatorio.
# Tiene dos estados muy distintos según la fase del torneo:
# - "bloqueado": si todavía estamos en fase de grupos, muestra cuántos partidos
#   faltan y si ya se puede avanzar a eliminatorias.
# - "activo": si ya estamos en eliminatorias, carga el bracket completo con
#   todas las rondas y el partido por el tercer lugar.
# Eso sí, sin esta lógica de dos estados la vista tendría que decidir sola
# qué mostrar según el status, lo que complicaría demasiado la vista ERB.
class KnockoutController < ApplicationController
  # Los 72 partidos de fase de grupos: 12 grupos × 6 partidos cada uno.
  # Esta constante es el tope que define si la fase de grupos está completa.
  TOTAL_GROUP_MATCHES = 72

  def index
    tournament = ApiClient.tournament

    if tournament["status"] == "group_stage" || tournament["status"] == "setup"
      # El torneo todavía está en fase de grupos. Calculamos cuántos partidos
      # faltan para saber si se puede avanzar o no.
      groups   = ApiClient.groups
      played   = played_group_matches(groups)
      @locked           = true
      @remaining        = TOTAL_GROUP_MATCHES - played
      # Cuando remaining llega a 0, la vista muestra el botón "AVANZAR A ELIMINATORIAS".
      @ready_to_advance = @remaining == 0
      @rounds           = []
      @champion  = nil
      @runner_up = nil
      @third     = nil
    else
      # Ya estamos en eliminatorias. Cargamos el bracket completo.
      data   = ApiClient.knockout_bracket
      rounds = data["rounds"] || []

      # El partido por el tercer lugar tiene su propia sección en la vista,
      # separada del bracket principal, por eso lo separamos aquí.
      third_round    = rounds.find { |r| r["phase"] == "3rd" }
      bracket_rounds = rounds.reject { |r| r["phase"] == "3rd" }

      @locked = false
      @rounds = bracket_rounds.map do |r|
        {
          name:    round_name(r["phase"]),
          matches: r["matches"].map { |m| build_bracket_match(m) }
        }
      end

      @champion  = team_brief(tournament["champion"])
      @runner_up = team_brief(tournament["runner_up"])

      # Si el partido por el tercer lugar existe y tiene datos, lo construimos.
      @third = if third_round && (tm = third_round["matches"].first)
        build_bracket_match(tm)
      end
    end
  rescue StandardError
    # En caso de error del backend, mostramos el bracket bloqueado con el
    # máximo de partidos faltantes para no dar acceso a eliminatorias.
    @locked    = true
    @remaining = TOTAL_GROUP_MATCHES
    @rounds    = []
    @champion  = nil
    @runner_up = nil
    @third     = nil
  end

  # Este método simula un partido eliminatorio y luego llama tournament_advance
  # para que el backend calcule el ganador y lo propague a la siguiente ronda.
  # Eso sí, sin el tournament_advance el ganador se guardaría pero el siguiente
  # partido no se actualizaría con los equipos que clasificaron.
  # Responde con JSON porque la vista lo llama via fetch (no con un form normal).
  def simulate
    ApiClient.simulate_match(params[:id])
    ApiClient.tournament_advance
    render json: { ok: true }
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end

  # Este método registra un resultado manual en un partido eliminatorio.
  # Los goles de prórroga van separados de los reglamentarios para que el backend
  # pueda calcular el total correctamente. Las penales también se envían por si
  # el partido terminó igualado después de la prórroga.
  def result
    goals = {
      home_goals:       params[:home_goals].to_i,
      away_goals:       params[:away_goals].to_i,
      # Por ahora la vista manda 0 en prórroga; está preparado para cuando
      # se agregue el formulario extendido.
      home_extra_goals: 0,
      away_extra_goals: 0,
      home_penalties:   params[:home_penalties].to_i,
      away_penalties:   params[:away_penalties].to_i
    }
    ApiClient.record_result(params[:id], goals)
    ApiClient.tournament_advance
    render json: { ok: true }
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end
end
