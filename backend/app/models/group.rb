# Group — uno de los 12 grupos del torneo (A–L), con 4 equipos.
class Group < ApplicationRecord
  MAX_TEAMS = 4

  belongs_to :tournament
  has_many :teams, dependent: :destroy
  has_many :matches, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { scope: :tournament_id }

  # Tabla de posiciones ordenada según los criterios de desempate FIFA.
  def standings
    teams.sort_by(&:ranking_key)
  end

  # ¿Ya se jugaron todos los partidos del grupo?
  def completed?
    matches.any? && matches.where(status: "scheduled").none?
  end

  # Primer y segundo lugar del grupo (clasificados directos).
  def qualified_teams
    standings.first(2)
  end

  # Tercer lugar del grupo (candidato a "mejor tercero").
  def third_place_team
    standings[2]
  end
end
