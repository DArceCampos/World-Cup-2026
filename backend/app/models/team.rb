# Team representa una selección participante en el torneo.
# Su función es almacenar la identidad del equipo (nombre, código) y sus
# estadísticas acumuladas. Eso sí, el equipo no calcula sus propias estadísticas:
# eso lo hace MatchResultRecorder cada vez que se registra un resultado.
# El equipo solo almacena y expone su estado actual.
class Team < ApplicationRecord
  belongs_to :group
  has_one :tournament, through: :group

  # Un equipo puede aparecer como local o visitante en los partidos, por eso
  # hay dos asociaciones has_many hacia Match con foreign keys distintos.
  # Sin esta separación, no habría forma de saber en cuáles partidos jugó
  # el equipo de local y en cuáles de visitante.
  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :destroy
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :destroy

  validates :name, presence: true

  # Esta validación impide que se creen más de 4 equipos en un mismo grupo.
  # Solo se ejecuta al crear (on: :create) porque mover un equipo de grupo
  # es una operación diferente que no debería estar sujeta a este límite.
  validate :group_not_full, on: :create

  # Este método devuelve todos los partidos del equipo, tanto de local como
  # de visitante, en una sola consulta SQL con OR. Es útil para saber si un
  # equipo tiene partidos registrados antes de intentar eliminarlo.
  def matches
    Match.where("home_team_id = :id OR away_team_id = :id", id: id)
  end

  # Este es el método más importante del equipo: implementa el orden oficial
  # FIFA para desempates. Devuelve un array que Ruby usa para comparar equipos.
  # Los valores negativos hacen que sort_by los ordene de mayor a menor:
  # primero por puntos, luego diferencia de goles, luego goles a favor,
  # y si todo lo demás es igual, alfabéticamente por nombre.
  def ranking_key
    [-points, -goal_difference, -goals_for, name]
  end

  private

  # Esta validación verifica que el grupo no esté lleno antes de agregar
  # un equipo más. Usa Group::MAX_TEAMS para no duplicar el valor 4.
  def group_not_full
    return if group.nil?

    if group.teams.count >= Group::MAX_TEAMS
      errors.add(:group, "ya tiene #{Group::MAX_TEAMS} equipos")
    end
  end
end
