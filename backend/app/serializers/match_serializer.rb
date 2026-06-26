# MatchSerializer convierte un objeto Match en un hash JSON para la API.
# Su función es exponer el marcador completo del partido (tiempo reglamentario,
# prórroga y penales), el ganador calculado, y la identidad de ambos equipos.
# Eso sí, para los equipos usa TeamSerializer.brief en lugar de la versión
# completa — dentro de un partido no hace falta saber los puntos del equipo.
class MatchSerializer
  def initialize(match)
    @match = match
  end

  # Este método lo que hace es construir la representación completa del partido.
  # El ganador se calcula llamando a match.winner, que aplica la lógica correcta
  # según la fase (grupos vs. eliminatoria). Si el partido no se ha jugado,
  # winner devuelve nil y TeamSerializer.brief(nil) también devuelve nil.
  def as_json(*)
    {
      id: @match.id,
      phase: @match.phase,
      group_id: @match.group_id,
      round_number: @match.round_number,
      status: @match.status,
      # brief devuelve solo { id, name, code } — suficiente para mostrar el partido.
      home_team: TeamSerializer.brief(@match.home_team),
      away_team: TeamSerializer.brief(@match.away_team),
      home_goals: @match.home_goals,
      away_goals: @match.away_goals,
      home_extra_goals: @match.home_extra_goals,
      away_extra_goals: @match.away_extra_goals,
      home_penalties: @match.home_penalties,
      away_penalties: @match.away_penalties,
      # El ganador se calcula dinámicamente desde el modelo, no se guarda en BD.
      winner: TeamSerializer.brief(@match.winner)
    }
  end
end
