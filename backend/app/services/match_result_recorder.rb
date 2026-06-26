# MatchResultRecorder es el servicio más importante del sistema.
# Su función es registrar el resultado de un partido y actualizar las
# estadísticas de ambos equipos involucrados. Eso sí, sin este servicio
# el sistema no podría llevar la tabla de posiciones correctamente —
# los modelos no se actualizan solos, alguien tiene que hacerlo.
#
# El diseño intencional aquí es que el controlador no sabe nada de cómo
# se calculan las estadísticas: simplemente llama a .call y delega.
class MatchResultRecorder
  # Puntos que se otorgan según el resultado del partido, según las reglas FIFA.
  POINTS_WIN  = 3
  POINTS_DRAW = 1

  # Esta excepción propia se lanza cuando el resultado enviado no es válido
  # (goles negativos, prórroga en grupos, etc.). Así el controlador puede
  # capturarla y responder con un 422 sin mezclar lógica de validación.
  class InvalidResult < StandardError; end

  def initialize(match, params)
    @match  = match
    @params = params
  end

  # Este método es el punto de entrada del servicio. Lo que hace es:
  # 1. Si el partido ya estaba jugado, deshacer las estadísticas anteriores.
  # 2. Asignar y validar el nuevo marcador.
  # 3. Marcar el partido como jugado y guardarlo.
  # 4. Actualizar las estadísticas de ambos equipos con el nuevo resultado.
  # Todo ocurre dentro de una transacción para garantizar que si algo falla
  # a mitad, los datos queden exactamente como estaban antes.
  def call
    ActiveRecord::Base.transaction do
      revert_team_stats if @match.played? && @match.group_phase?

      assign_score
      @match.status = "played"
      @match.save!

      update_team_stats if @match.group_phase?
    end

    @match
  end

  private

  # Este método asigna los valores del marcador al partido y luego valida
  # que sean coherentes. Se llama .to_i en cada valor para convertir nil
  # a 0 de forma segura si algún campo no viene en los parámetros.
  def assign_score
    @match.home_goals       = @params[:home_goals].to_i
    @match.away_goals       = @params[:away_goals].to_i
    @match.home_extra_goals = @params[:home_extra_goals].to_i
    @match.away_extra_goals = @params[:away_extra_goals].to_i
    @match.home_penalties   = @params[:home_penalties].to_i
    @match.away_penalties   = @params[:away_penalties].to_i

    validate_score!
  end

  # Este método lo que hace es verificar que el marcador sea válido.
  # Hay dos reglas: los goles no pueden ser negativos, y en la fase de
  # grupos no puede haber prórroga ni penales porque esas son reglas
  # exclusivas de la fase eliminatoria.
  def validate_score!
    if @match.home_goals.negative? || @match.away_goals.negative?
      raise InvalidResult, "Los goles no pueden ser negativos"
    end

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

  # Este método lo que hace es deshacer el impacto del resultado anterior
  # sobre las estadísticas de ambos equipos. Se necesita porque si alguien
  # corrige el resultado de un partido ya jugado, hay que primero restar
  # lo que se sumó antes para luego aplicar el nuevo resultado limpiamente.
  # Eso sí, sin este paso una corrección duplicaría o mezclaría estadísticas.
  def revert_team_stats
    home = @match.home_team
    away = @match.away_team

    revert_goals(home, scored: @match.home_goals, conceded: @match.away_goals)
    revert_goals(away, scored: @match.away_goals, conceded: @match.home_goals)

    if @match.home_goals > @match.away_goals
      revert_win(home); revert_loss(away)
    elsif @match.away_goals > @match.home_goals
      revert_win(away); revert_loss(home)
    else
      revert_draw(home); revert_draw(away)
    end

    home.save!
    away.save!
  end

  # Este método aplica el nuevo resultado a las estadísticas de ambos equipos.
  # Primero actualiza goles para los dos, y luego aplica puntos según quién ganó.
  def update_team_stats
    home = @match.home_team
    away = @match.away_team

    apply_goals(home, scored: @match.home_goals, conceded: @match.away_goals)
    apply_goals(away, scored: @match.away_goals, conceded: @match.home_goals)

    if @match.home_goals > @match.away_goals
      register_win(home); register_loss(away)
    elsif @match.away_goals > @match.home_goals
      register_win(away); register_loss(home)
    else
      register_draw(home); register_draw(away)
    end

    home.save!
    away.save!
  end

  # Suma goles y partidos jugados al equipo. La diferencia de goles se
  # recalcula siempre desde cero para evitar acumulación de errores.
  def apply_goals(team, scored:, conceded:)
    team.matches_played   += 1
    team.goals_for        += scored
    team.goals_against    += conceded
    team.goal_difference   = team.goals_for - team.goals_against
  end

  # Hace lo opuesto de apply_goals — descuenta goles y partidos jugados.
  def revert_goals(team, scored:, conceded:)
    team.matches_played   -= 1
    team.goals_for        -= scored
    team.goals_against    -= conceded
    team.goal_difference   = team.goals_for - team.goals_against
  end

  # Los siguientes seis métodos aplican o revierten el resultado (W/D/L)
  # y los puntos correspondientes para un equipo. Están separados en métodos
  # pequeños para que update_team_stats y revert_team_stats sean legibles.
  def register_win(team)
    team.wins   += 1
    team.points += POINTS_WIN
  end

  def register_draw(team)
    team.draws  += 1
    team.points += POINTS_DRAW
  end

  def register_loss(team)
    team.losses += 1
  end

  def revert_win(team)
    team.wins   -= 1
    team.points -= POINTS_WIN
  end

  def revert_draw(team)
    team.draws  -= 1
    team.points -= POINTS_DRAW
  end

  def revert_loss(team)
    team.losses -= 1
  end
end
