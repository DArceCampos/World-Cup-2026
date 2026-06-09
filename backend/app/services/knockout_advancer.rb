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
  def build_round_of_32
    raise NotReady, "Aún hay partidos de grupo pendientes" unless all_groups_completed?

    qualifiers = collect_qualifiers
    raise NotReady, "No hay 32 clasificados" unless qualifiers.size == 32

    ActiveRecord::Base.transaction do
      create_matches_for_phase("r32", qualifiers)
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

  private

  def all_groups_completed?
    @tournament.groups.all?(&:completed?)
  end

  # 24 directos (1° y 2° de cada grupo) + 8 mejores terceros.
  def collect_qualifiers
    @tournament.groups.flat_map(&:qualified_teams) + @tournament.best_third_places
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
