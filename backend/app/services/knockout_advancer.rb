# KnockoutAdvancer — gestiona la construcción y el avance de la fase
# eliminatoria.
#
# Tiene dos responsabilidades coordinadas bajo un mismo concepto (avanzar el
# bracket):
#   * build_round_of_32: al terminar la fase de grupos, arma los
#     dieciseisavos con los 24 clasificados directos + 8 mejores terceros.
#   * advance!: dado que una ronda eliminatoria terminó, crea los partidos
#     de la siguiente ronda emparejando a los ganadores.
#
# El emparejamiento es secuencial (ganador del partido 1 vs ganador del 2,
# etc.), lo cual es una simplificación aceptable para este sistema: el orden
# del bracket se define por round_number al sembrar los dieciseisavos.
class KnockoutAdvancer
  class NotReady < StandardError; end

  # Secuencia de rondas eliminatorias y su siguiente fase.
  # r32 = dieciseisavos, r16 = octavos, qf = cuartos, sf = semifinales.
  NEXT_PHASE = {
    "r32" => "r16",
    "r16" => "qf",
    "qf"  => "sf",
    "sf"  => "final" # las semifinales además generan el partido por el 3er lugar
  }.freeze

  def initialize(tournament)
    @tournament = tournament
  end

  # Construye los dieciseisavos de final (16 partidos / 32 equipos).
  # Debe llamarse cuando todos los grupos están completos.
  #
  # Emparejamiento cruzado FIFA 2026: los grupos se emparejan en pares
  # (A,B), (C,D), (E,F), (G,H), (I,J), (K,L). Dentro de cada par:
  #   Primera mitad del bracket: 1°(G_impar) vs 2°(G_par)
  #   Segunda mitad del bracket: 1°(G_par)   vs 2°(G_impar)
  # Garantiza que dos equipos del mismo grupo solo puedan cruzarse en la Final.
  def build_round_of_32
    raise NotReady, "Aún hay partidos de grupo pendientes" unless all_groups_completed?

    groups = @tournament.groups.order(:name)
    thirds = @tournament.best_third_places

    raise NotReady, "Se necesitan 12 grupos" unless groups.size == 12
    raise NotReady, "No hay suficientes mejores terceros (#{thirds.size}/8)" unless thirds.size == 8

    ActiveRecord::Base.transaction do
      seed_round_of_32(groups, thirds)
      @tournament.update!(status: "knockout")
    end
  end

  # Avanza la fase eliminatoria a partir de la ronda completada más reciente.
  # Retorna true si creó una nueva ronda, false si no había nada que avanzar.
  def advance!
    current = current_completed_phase
    return false if current.nil?

    next_phase = NEXT_PHASE[current]
    return false if next_phase.nil?

    # Idempotencia: si la siguiente ronda ya fue generada, no la recrea
    # (evita duplicar final/3er lugar al registrar el resultado de la final).
    return false if @tournament.matches.where(phase: next_phase).exists?

    winners = winners_of(current)

    ActiveRecord::Base.transaction do
      if current == "sf"
        build_final_and_third_place(current)
      else
        create_matches_for_phase(next_phase, winners)
      end
    end

    true
  end

  # Cuando una ronda siguiente ya existe y se re-registra un resultado,
  # actualiza el equipo (ganador o perdedor) en el partido siguiente del bracket.
  # También resetea ese partido a "scheduled" para que sea re-jugable.
  def propagate_winner_change(match)
    next_phase = NEXT_PHASE[match.phase]
    return unless next_phase

    new_winner = match.winner
    new_loser  = match.loser
    return unless new_winner

    # round_number impar → home_team del partido siguiente; par → away_team
    next_round = ((match.round_number.to_f) / 2).ceil
    is_home    = match.round_number.odd?

    if match.phase == "sf"
      # Actualizar la final con el nuevo ganador
      final_match = @tournament.matches.find_by(phase: "final", round_number: next_round)
      if final_match
        reset_next_match(final_match, is_home, new_winner)
      end

      # Actualizar el 3er lugar con el nuevo perdedor
      third_match = @tournament.matches.find_by(phase: "3rd", round_number: next_round)
      if third_match && new_loser
        reset_next_match(third_match, is_home, new_loser)
      end
    else
      next_match = @tournament.matches.find_by(phase: next_phase, round_number: next_round)
      if next_match
        reset_next_match(next_match, is_home, new_winner)
      end
    end
  end

  private

  def reset_next_match(next_match, is_home, new_team)
    attrs = {
      status: "scheduled",
      home_goals: 0, away_goals: 0,
      home_extra_goals: 0, away_extra_goals: 0,
      home_penalties: 0, away_penalties: 0
    }
    attrs[is_home ? :home_team_id : :away_team_id] = new_team.id
    next_match.update!(attrs)
  end

  def all_groups_completed?
    @tournament.groups.all?(&:completed?)
  end

  # Siembra los 16 partidos de dieciseisavos con cruce cruzado entre grupos.
  # Primera mitad (rounds 1-8):  1°G_impar vs 2°G_par  + mejores terceros 1-4
  # Segunda mitad (rounds 9-16): 1°G_par   vs 2°G_impar + mejores terceros 5-8
  def seed_round_of_32(groups, thirds)
    pairs = groups.each_slice(2).to_a  # [[A,B],[C,D],[E,F],[G,H],[I,J],[K,L]]

    first_half  = pairs.map { |g1, g2| [g1.standings[0], g2.standings[1]] }
    second_half = pairs.map { |g1, g2| [g2.standings[0], g1.standings[1]] }

    first_half  += [[thirds[0], thirds[1]], [thirds[2], thirds[3]]]
    second_half += [[thirds[4], thirds[5]], [thirds[6], thirds[7]]]

    (first_half + second_half).each_with_index do |(home, away), i|
      @tournament.matches.create!(
        phase:        "r32",
        round_number: i + 1,
        home_team:    home,
        away_team:    away,
        status:       "scheduled"
      )
    end
  end

  # Crea los partidos de una fase emparejando equipos de dos en dos.
  def create_matches_for_phase(phase, teams)
    teams.each_slice(2).with_index(1) do |(home, away), round_number|
      @tournament.matches.create!(
        phase: phase,
        round_number: round_number,
        home_team: home,
        away_team: away,
        status: "scheduled"
      )
    end
  end

  # La última fase eliminatoria que está completamente jugada.
  def current_completed_phase
    %w[r32 r16 qf sf].reverse.find do |phase|
      matches = @tournament.matches.where(phase: phase)
      matches.any? && matches.pending.none?
    end
  end

  # Ganadores de una fase, ordenados por round_number para mantener el bracket.
  def winners_of(phase)
    @tournament.matches
               .where(phase: phase)
               .order(:round_number)
               .map(&:winner)
  end

  # Las semifinales producen la final (ganadores) y el partido por el
  # tercer lugar (perdedores).
  def build_final_and_third_place(sf_phase)
    sf_matches = @tournament.matches.where(phase: sf_phase).order(:round_number)
    winners = sf_matches.map(&:winner)
    losers = sf_matches.map(&:loser)

    create_matches_for_phase("3rd", losers)
    create_matches_for_phase("final", winners)
  end
end
