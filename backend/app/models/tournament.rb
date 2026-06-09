# Tournament — Aggregate Root del torneo.
#
# Representa la Copa del Mundo completa y controla su estado global
# (setup -> group_stage -> knockout -> finished). Es el punto de entrada
# para consultar campeón, subcampeón y tercer lugar.
class Tournament < ApplicationRecord
  # Estados posibles del torneo (máquina de estados simple).
  STATUSES = %w[setup group_stage knockout finished].freeze

  has_many :groups, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :teams, through: :groups

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  # --- Consultas de estado -------------------------------------------------

  def group_stage?
    status == "group_stage"
  end

  def knockout?
    status == "knockout"
  end

  def finished?
    status == "finished"
  end

  # Partido de la final (si ya existe en el bracket).
  def final_match
    matches.find_by(phase: "final")
  end

  # Partido por el tercer lugar.
  def third_place_match
    matches.find_by(phase: "3rd")
  end

  # Los 8 mejores terceros lugares (clasificados que completan los 32 de
  # dieciseisavos junto a los 24 directos), ordenados por desempate FIFA.
  THIRD_PLACE_SPOTS = 8
  def best_third_places
    groups.map(&:third_place_team).compact.sort_by(&:ranking_key).first(THIRD_PLACE_SPOTS)
  end

  # --- Resultados finales --------------------------------------------------

  # El campeón es el ganador de la final.
  def champion
    final_match&.played? ? final_match.winner : nil
  end

  # El subcampeón es el perdedor de la final.
  def runner_up
    final_match&.played? ? final_match.loser : nil
  end

  # El tercer lugar es el ganador del partido por el tercer puesto.
  def third_place
    third_place_match&.played? ? third_place_match.winner : nil
  end
end
