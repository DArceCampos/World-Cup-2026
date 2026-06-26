# TeamSerializer convierte un objeto Team en un hash JSON listo para la API.
# Su función es aislar la representación JSON del modelo: si el modelo Team
# cambia internamente, el contrato de la API no cambia mientras este serializer
# se mantenga igual. Eso sí, sin los serializers los controladores tendrían que
# armar el JSON manualmente en cada acción, lo que sería muy repetitivo.
class TeamSerializer
  def initialize(team)
    @team = team
  end

  # Este método lo que hace es construir la versión completa del equipo con
  # todas sus estadísticas. Se usa en las tablas de posiciones y en el listado
  # general de equipos, donde se necesitan todos los datos.
  def as_json(*)
    {
      id: @team.id,
      name: @team.name,
      code: @team.code,
      group_id: @team.group_id,
      points: @team.points,
      goals_for: @team.goals_for,
      goals_against: @team.goals_against,
      goal_difference: @team.goal_difference,
      matches_played: @team.matches_played,
      wins: @team.wins,
      draws: @team.draws,
      losses: @team.losses
    }
  end

  # Este método de clase lo que hace es construir una versión mínima del equipo
  # con solo su identidad: id, nombre y código. Se usa dentro de los partidos,
  # donde no tiene sentido enviar las 12 estadísticas del equipo — solo se
  # necesita saber quién es. El chequeo nil evita errores cuando un partido
  # todavía no tiene equipo asignado (posición por definir en eliminatorias).
  def self.brief(team)
    return nil if team.nil?

    { id: team.id, name: team.name, code: team.code }
  end
end
