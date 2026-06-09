# MatchSimulator — genera resultados aleatorios y los registra reutilizando
# MatchResultRecorder (para las stats) y KnockoutAdvancer (para el bracket).
#
# Expone cuatro niveles de simulación: un partido, un grupo, todos los grupos
# o el torneo completo. Es idempotente: omite los partidos ya jugados.
class MatchSimulator
  MAX_GOALS = 4

  # Simula un único partido y lo retorna.
  def self.match(match)
    return match if match.played?

    MatchResultRecorder.new(match, random_score(match)).call
    match
  end

  # Simula los partidos pendientes de un grupo.
  def self.group(group)
    simulate(group.matches.pending)
  end

  # Simula los partidos pendientes de toda la fase de grupos.
  def self.all_groups(tournament)
    simulate(tournament.matches.group_phase.pending)
  end

  # Simula el torneo completo: grupos, eliminatorias y final.
  def self.tournament(tournament)
    simulated = all_groups(tournament)

    advancer = KnockoutAdvancer.new(tournament)
    advancer.build_round_of_32 if tournament.group_stage?

    loop do
      pending = tournament.matches.knockout.pending
      break if pending.empty?

      simulated += simulate(pending)
      break if tournament.final_match&.played? # la final es la última ronda

      advancer.advance!
    end

    tournament.update!(status: "finished") if tournament.final_match&.played?
    simulated
  end

  # Simula una colección de partidos en una transacción y retorna los jugados.
  def self.simulate(matches)
    ActiveRecord::Base.transaction do
      matches.reject(&:played?).each { |m| match(m) }
    end
  end
  private_class_method :simulate

  # Marcador aleatorio. En eliminatoria un empate se define por penales.
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
