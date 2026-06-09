# TeamSerializer — convierte un Team en un hash JSON.
#
# Expone solo los atributos relevantes (Interface Segregation): un consumidor
# de la tabla de posiciones recibe exactamente las estadísticas que necesita.
class TeamSerializer
  def initialize(team)
    @team = team
  end

  # Versión completa con estadísticas (para tabla de posiciones).
  def as_json(*)
    {
      id: @team.id,
      name: @team.name,
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

  # Versión mínima (solo identidad), útil dentro de partidos.
  def self.brief(team)
    return nil if team.nil?

    { id: team.id, name: team.name }
  end
end
