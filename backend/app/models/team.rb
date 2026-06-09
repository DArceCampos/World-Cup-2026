# Team — una selección participante.
#
# Mantiene sus estadísticas acumuladas (puntos, goles, etc.) que son
# actualizadas por MatchResultRecorder cada vez que se registra un
# resultado de fase de grupos. No recalcula nada por sí mismo: solo
# almacena y expone su estado.
class Team < ApplicationRecord
  belongs_to :group
  has_one :tournament, through: :group

  # Partidos como local y como visitante (ambos apuntan a esta tabla).
  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :destroy
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :destroy

  validates :name, presence: true

  # Validación de regla de negocio: un grupo no puede tener más de 4 equipos.
  validate :group_not_full, on: :create

  # Todos los partidos del equipo (local + visitante).
  def matches
    Match.where("home_team_id = :id OR away_team_id = :id", id: id)
  end

  # Clave de ordenamiento FIFA (mayor es mejor): puntos -> diferencia de
  # goles -> goles a favor -> nombre. Usada por la tabla de posiciones y por
  # la selección de mejores terceros.
  def ranking_key
    [-points, -goal_difference, -goals_for, name]
  end

  private

  def group_not_full
    return if group.nil?

    if group.teams.count >= Group::MAX_TEAMS
      errors.add(:group, "ya tiene #{Group::MAX_TEAMS} equipos")
    end
  end
end
