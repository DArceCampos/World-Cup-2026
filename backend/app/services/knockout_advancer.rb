# KnockoutAdvancer es el servicio que construye y avanza el bracket eliminatorio.
# Su función es tomar los clasificados de la fase de grupos y crear los partidos
# de dieciseisavos, y después ir creando cada ronda siguiente a medida que la
# anterior se completa. Eso sí, sin este servicio el torneo nunca pasaría de
# la fase de grupos — no habría forma de generar los partidos eliminatorios.
class KnockoutAdvancer
  # Esta excepción se lanza cuando se intenta avanzar antes de que las
  # condiciones estén listas (grupos incompletos, pocos terceros clasificados).
  class NotReady < StandardError; end

  # Este hash define la secuencia de fases eliminatorias. La clave es la fase
  # actual y el valor es la siguiente. Usar un hash en lugar de un if-elsif
  # permite agregar nuevas fases simplemente extendiendo el hash.
  NEXT_PHASE = {
    "r32" => "r16",
    "r16" => "qf",
    "qf"  => "sf",
    "sf"  => "final"
  }.freeze

  def initialize(tournament)
    @tournament = tournament
  end

  # Este método construye los 16 partidos de dieciseisavos de final.
  # Debe llamarse cuando todos los grupos terminaron. Lo que hace es:
  # 1. Verificar que todos los grupos estén completos.
  # 2. Obtener los 8 mejores terceros clasificados.
  # 3. Emparejar equipos con el cruce FIFA cruzado entre grupos pares e impares,
  #    para que equipos del mismo grupo no se puedan cruzar antes de la final.
  # 4. Cambiar el torneo a estado "knockout".
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

  # Este método avanza la fase eliminatoria a la siguiente ronda.
  # Lo que hace es: buscar la última fase completada, determinar cuál es la
  # siguiente usando NEXT_PHASE, y crear los partidos emparejando los ganadores.
  # Es idempotente: si la siguiente ronda ya existe, retorna false sin crear
  # nada — esto evita duplicar la final si alguien llama advance! dos veces.
  def advance!
    current = current_completed_phase
    return false if current.nil?

    next_phase = NEXT_PHASE[current]
    return false if next_phase.nil?

    # Si la siguiente fase ya existe, no la recrear (idempotencia).
    return false if @tournament.matches.where(phase: next_phase).exists?

    winners = winners_of(current)

    ActiveRecord::Base.transaction do
      if current == "sf"
        # Las semifinales son un caso especial: producen DOS partidos a la vez:
        # la final (con los ganadores) y el tercer lugar (con los perdedores).
        build_final_and_third_place(current)
      else
        create_matches_for_phase(next_phase, winners)
      end
    end

    true
  end

  # Este método lo que hace es propagar el cambio de ganador cuando se corrige
  # el resultado de un partido eliminatorio. Si el partido siguiente ya existe,
  # lo actualiza con el nuevo ganador (o perdedor, en el caso de las semifinales)
  # y lo resetea a "scheduled" para que se pueda jugar de nuevo.
  # Eso sí, sin este método corregir un resultado en semifinales dejaría la
  # final con el equipo equivocado.
  def propagate_winner_change(match)
    next_phase = NEXT_PHASE[match.phase]
    return unless next_phase

    new_winner = match.winner
    new_loser  = match.loser
    return unless new_winner

    # Si el round_number es impar, este partido ocupa el slot de local en el
    # siguiente partido; si es par, ocupa el de visitante.
    next_round = ((match.round_number.to_f) / 2).ceil
    is_home    = match.round_number.odd?

    if match.phase == "sf"
      # En semifinales hay que actualizar dos partidos: la final con el ganador
      # y el partido por el tercer lugar con el perdedor.
      final_match = @tournament.matches.find_by(phase: "final", round_number: next_round)
      reset_next_match(final_match, is_home, new_winner) if final_match

      third_match = @tournament.matches.find_by(phase: "3rd", round_number: next_round)
      reset_next_match(third_match, is_home, new_loser) if third_match && new_loser
    else
      next_match = @tournament.matches.find_by(phase: next_phase, round_number: next_round)
      reset_next_match(next_match, is_home, new_winner) if next_match
    end
  end

  private

  # Este método actualiza el equipo en el partido siguiente y lo resetea a
  # "scheduled" para que pueda volver a jugarse con la nueva combinación.
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

  # Verifica que los 12 grupos hayan terminado todos sus partidos.
  def all_groups_completed?
    @tournament.groups.all?(&:completed?)
  end

  # Este método siembra los 16 partidos de dieciseisavos con el cruce FIFA.
  # Los grupos se emparejan en pares (A,B), (C,D), etc. Dentro de cada par:
  # - Primera mitad del bracket: 1°(grupo impar) vs 2°(grupo par)
  # - Segunda mitad del bracket: 1°(grupo par) vs 2°(grupo impar)
  # Esto garantiza que dos equipos del mismo grupo no se puedan cruzar
  # antes de la final, cumpliendo el reglamento FIFA 2026.
  def seed_round_of_32(groups, thirds)
    pairs = groups.each_slice(2).to_a

    first_half  = pairs.map { |g1, g2| [g1.standings[0], g2.standings[1]] }
    second_half = pairs.map { |g1, g2| [g2.standings[0], g1.standings[1]] }

    # Los 8 mejores terceros se distribuyen: 4 en cada mitad del bracket.
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

  # Este método crea los partidos de una fase emparejando equipos de dos en dos
  # en orden: ganador 1 vs ganador 2, ganador 3 vs ganador 4, etc.
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

  # Este método busca la última fase eliminatoria que esté completamente jugada.
  # Busca en orden inverso (sf primero) para encontrar la más reciente.
  def current_completed_phase
    %w[r32 r16 qf sf].reverse.find do |phase|
      matches = @tournament.matches.where(phase: phase)
      matches.any? && matches.pending.none?
    end
  end

  # Devuelve los ganadores de una fase ordenados por round_number para que
  # el emparejamiento de la siguiente ronda respete el orden del bracket.
  def winners_of(phase)
    @tournament.matches
               .where(phase: phase)
               .order(:round_number)
               .map(&:winner)
  end

  # Las semifinales producen dos partidos simultáneamente: la final con los
  # ganadores de ambas semis, y el partido por el tercer lugar con los perdedores.
  def build_final_and_third_place(sf_phase)
    sf_matches = @tournament.matches.where(phase: sf_phase).order(:round_number)
    winners = sf_matches.map(&:winner)
    losers  = sf_matches.map(&:loser)

    create_matches_for_phase("3rd", losers)
    create_matches_for_phase("final", winners)
  end
end
