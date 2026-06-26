# Match representa un partido entre dos selecciones.
# Su función es almacenar el marcador completo (tiempo reglamentario, prórroga
# y penales) y determinar quién ganó aplicando las reglas correctas según la
# fase. Eso sí, sin este modelo no habría forma de registrar resultados ni de
# construir el bracket eliminatorio.
class Match < ApplicationRecord
  # Todas las fases posibles. "group" es la fase de grupos; las demás son
  # eliminatorias: r32=dieciseisavos, r16=octavos, qf=cuartos, sf=semifinales,
  # 3rd=tercer lugar, final=final.
  PHASES = %w[group r32 r16 qf sf 3rd final].freeze

  # Subconjunto de fases que son eliminatorias — se usa para los scopes
  # y para saber si un partido puede tener prórroga y penales.
  KNOCKOUT_PHASES = %w[r32 r16 qf sf 3rd final].freeze
  STATUSES = %w[scheduled played].freeze

  belongs_to :tournament
  # El group_id es opcional porque los partidos de eliminatoria no pertenecen
  # a ningún grupo — su group_id queda en NULL en la base de datos.
  belongs_to :group, optional: true
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"

  validates :phase, inclusion: { in: PHASES }
  validates :status, inclusion: { in: STATUSES }
  validate :teams_are_different

  # Estos scopes permiten filtrar partidos por tipo sin repetir condiciones SQL
  # en toda la aplicación. Por ejemplo, tournament.matches.knockout.pending
  # devuelve todos los partidos eliminatorios pendientes del torneo.
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

  # Estos dos métodos suman los goles del tiempo reglamentario más la prórroga.
  # No incluyen penales porque los penales no son goles del partido — solo
  # sirven para desempatar en caso de empate después de la prórroga.
  def home_total_goals
    home_goals.to_i + home_extra_goals.to_i
  end

  def away_total_goals
    away_goals.to_i + away_extra_goals.to_i
  end

  # Este es el método más importante del partido: determina quién ganó.
  # La lógica es diferente según la fase:
  # - En grupos: si hay empate retorna nil (los empates son válidos en grupos).
  # - En eliminatorias: si hay empate en goles totales, se va a penales.
  # Eso sí, sin este método ninguna otra parte del sistema sabría determinar
  # el ganador — KnockoutAdvancer lo usa para armar la siguiente ronda.
  def winner
    return nil unless played?

    if home_total_goals > away_total_goals
      home_team
    elsif away_total_goals > home_total_goals
      away_team
    elsif knockout?
      # En eliminatoria un empate se resuelve por penales.
      penalty_winner
    end
  end

  # El perdedor es simplemente el equipo que no ganó. Si winner es nil
  # (empate en grupos), loser también es nil.
  def loser
    w = winner
    return nil if w.nil?

    w == home_team ? away_team : home_team
  end

  private

  # Este método lo que hace es determinar el ganador de penales comparando
  # los campos home_penalties y away_penalties. Si ninguno tiene penales
  # registrados, retorna nil (el partido aún no se ha resuelto).
  def penalty_winner
    if home_penalties.to_i > away_penalties.to_i
      home_team
    elsif away_penalties.to_i > home_penalties.to_i
      away_team
    end
  end

  # Validación de integridad: un equipo no puede jugar contra sí mismo.
  def teams_are_different
    if home_team_id.present? && home_team_id == away_team_id
      errors.add(:away_team, "no puede ser el mismo que el equipo local")
    end
  end
end
