# MatchSimulator genera resultados aleatorios y los registra en la base de datos.
# Su función es permitir simular partidos automáticamente sin tener que
# ingresar marcadores manualmente. Eso sí, no inventa su propia lógica de
# registro — reutiliza MatchResultRecorder para que las estadísticas siempre
# se actualicen correctamente, sin importar cómo se originó el resultado.
#
# Es idempotente: si un partido ya fue jugado, lo omite sin error.
class MatchSimulator
  # El máximo de goles que puede marcar un equipo en una simulación.
  # Con 4, los resultados son realistas para un torneo de fútbol.
  MAX_GOALS = 4

  # Este método simula un único partido. Si ya está jugado, lo retorna sin
  # cambios. Si no, genera un marcador aleatorio y lo registra usando
  # MatchResultRecorder, que se encarga de actualizar las estadísticas.
  def self.match(match)
    return match if match.played?

    MatchResultRecorder.new(match, random_score(match)).call
    match
  end

  # Este método simula todos los partidos pendientes de un grupo específico.
  # Los partidos ya jugados se saltan automáticamente dentro de simulate.
  def self.group(group)
    simulate(group.matches.pending)
  end

  # Este método simula todos los partidos pendientes de la fase de grupos
  # completa — los 72 partidos del torneo si ninguno fue jugado aún.
  def self.all_groups(tournament)
    simulate(tournament.matches.group_phase.pending)
  end

  # Este método simula el torneo completo desde donde esté: primero los
  # grupos, luego construye el bracket y simula todas las rondas eliminatorias
  # hasta que la final queda jugada. El loop se detiene cuando ya no quedan
  # partidos pendientes o cuando la final está jugada. Eso sí, sin este método
  # simular un torneo completo requeriría llamar múltiples endpoints manualmente.
  def self.tournament(tournament)
    simulated = all_groups(tournament)

    advancer = KnockoutAdvancer.new(tournament)
    # Solo construye el bracket si el torneo todavía está en fase de grupos.
    advancer.build_round_of_32 if tournament.group_stage?

    loop do
      pending = tournament.matches.knockout.pending
      break if pending.empty?

      simulated += simulate(pending)
      # Si la final ya se jugó, el torneo terminó — no hay más rondas.
      break if tournament.final_match&.played?

      # Avanza al bracket de la siguiente ronda (R32→R16→QF→SF→Final).
      advancer.advance!
    end

    tournament.update!(status: "finished") if tournament.final_match&.played?
    simulated
  end

  # Este método privado simula una colección de partidos dentro de una
  # transacción. El .reject(&:played?) es una segunda salvaguarda contra
  # duplicar resultados, además de la que tiene self.match.
  def self.simulate(matches)
    ActiveRecord::Base.transaction do
      matches.reject(&:played?).each { |m| match(m) }
    end
  end
  private_class_method :simulate

  # Este método genera un marcador aleatorio. Para partidos de eliminatoria,
  # si el resultado empata, asigna penales: siempre 4-3 mezclados al azar
  # para garantizar que haya un ganador sin resultados de penales irreales.
  def self.random_score(match)
    home = rand(0..MAX_GOALS)
    away = rand(0..MAX_GOALS)
    score = { home_goals: home, away_goals: away }

    if match.knockout? && home == away
      score[:home_penalties], score[:away_penalties] = [4, 3].shuffle
    end

    score
  end
  private_class_method :random_score
end
