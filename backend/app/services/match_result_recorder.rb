# MatchResultRecorder — registra el resultado de un partido y, si es de
# fase de grupos, actualiza las estadísticas acumuladas de ambos equipos.
#
# Responsabilidad única (SRP): traducir un resultado en cambios de estado
# consistentes. Toda la operación corre en una transacción para garantizar
# que el partido y las estadísticas queden siempre sincronizados.
#
# Uso:
#   MatchResultRecorder.new(match, params).call
class MatchResultRecorder
  POINTS_WIN = 3
  POINTS_DRAW = 1

  # Error de dominio cuando el resultado es inválido.
  class InvalidResult < StandardError; end

  def initialize(match, params)
    @match = match
    @params = params
  end

  def call
    raise InvalidResult, "El partido ya tiene un resultado registrado" if @match.played?

    ActiveRecord::Base.transaction do
      assign_score
      @match.status = "played"
      @match.save!

      update_team_stats if @match.group_phase?
    end

    @match
  end

  private

  def assign_score
    @match.home_goals = @params[:home_goals].to_i
    @match.away_goals = @params[:away_goals].to_i
    @match.home_extra_goals = @params[:home_extra_goals].to_i
    @match.away_extra_goals = @params[:away_extra_goals].to_i
    @match.home_penalties = @params[:home_penalties].to_i
    @match.away_penalties = @params[:away_penalties].to_i

    validate_score!
  end

  def validate_score!
    if @match.home_goals.negative? || @match.away_goals.negative?
      raise InvalidResult, "Los goles no pueden ser negativos"
    end

    # En fase de grupos no hay prórroga ni penales.
    if @match.group_phase? && (penalties_present? || extra_present?)
      raise InvalidResult, "La fase de grupos no admite prórroga ni penales"
    end
  end

  def penalties_present?
    @match.home_penalties.positive? || @match.away_penalties.positive?
  end

  def extra_present?
    @match.home_extra_goals.positive? || @match.away_extra_goals.positive?
  end

  # Actualiza puntos, goles y récord (V/E/D) de ambos equipos.
  def update_team_stats
    home = @match.home_team
    away = @match.away_team

    apply_goals(home, scored: @match.home_goals, conceded: @match.away_goals)
    apply_goals(away, scored: @match.away_goals, conceded: @match.home_goals)

    if @match.home_goals > @match.away_goals
      register_win(home)
      register_loss(away)
    elsif @match.away_goals > @match.home_goals
      register_win(away)
      register_loss(home)
    else
      register_draw(home)
      register_draw(away)
    end

    home.save!
    away.save!
  end

  def apply_goals(team, scored:, conceded:)
    team.matches_played += 1
    team.goals_for += scored
    team.goals_against += conceded
    team.goal_difference = team.goals_for - team.goals_against
  end

  def register_win(team)
    team.wins += 1
    team.points += POINTS_WIN
  end

  def register_draw(team)
    team.draws += 1
    team.points += POINTS_DRAW
  end

  def register_loss(team)
    team.losses += 1
  end
end
