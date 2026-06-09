# Match — un partido entre dos selecciones.
#
# Sirve tanto para fase de grupos (group_id presente) como para fase
# eliminatoria (group_id nulo, phase distinta de "group"). Encapsula la
# lógica para determinar ganador y perdedor, incluyendo prórroga y penales.
class Match < ApplicationRecord
  # Fases del torneo. "group" = fase de grupos; el resto es eliminatoria.
  PHASES = %w[group r32 r16 qf sf 3rd final].freeze
  # NOTA: r32 = dieciseisavos (32 equipos), r16 = octavos, qf = cuartos,
  # sf = semifinales, 3rd = tercer lugar, final = final.

  KNOCKOUT_PHASES = %w[r32 r16 qf sf 3rd final].freeze
  STATUSES = %w[scheduled played].freeze

  belongs_to :tournament
  belongs_to :group, optional: true
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"

  validates :phase, inclusion: { in: PHASES }
  validates :status, inclusion: { in: STATUSES }
  validate :teams_are_different

  scope :group_phase, -> { where(phase: "group") }
  scope :knockout, -> { where(phase: KNOCKOUT_PHASES) }
  scope :pending, -> { where(status: "scheduled") }

  def played?
    status == "played"
  end

  def group_phase?
    phase == "group"
  end

  def knockout?
    KNOCKOUT_PHASES.include?(phase)
  end

  # Goles totales contando la prórroga (no incluye penales).
  def home_total_goals
    home_goals.to_i + home_extra_goals.to_i
  end

  def away_total_goals
    away_goals.to_i + away_extra_goals.to_i
  end

  # Determina el equipo ganador.
  # - En grupos puede haber empate (retorna nil).
  # - En eliminatoria se desempata por prórroga y luego por penales.
  def winner
    return nil unless played?

    if home_total_goals > away_total_goals
      home_team
    elsif away_total_goals > home_total_goals
      away_team
    elsif knockout?
      # Empate en eliminatoria: se define por penales.
      penalty_winner
    end
  end

  # El perdedor es el equipo que no ganó (nil si fue empate en grupos).
  def loser
    w = winner
    return nil if w.nil?

    w == home_team ? away_team : home_team
  end

  private

  def penalty_winner
    if home_penalties.to_i > away_penalties.to_i
      home_team
    elsif away_penalties.to_i > home_penalties.to_i
      away_team
    end
  end

  def teams_are_different
    if home_team_id.present? && home_team_id == away_team_id
      errors.add(:away_team, "no puede ser el mismo que el equipo local")
    end
  end
end
