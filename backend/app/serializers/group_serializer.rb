# GroupSerializer — convierte un Group en un hash JSON con su tabla de
# posiciones ya ordenada y, opcionalmente, sus partidos.
class GroupSerializer
  def initialize(group, include_matches: false)
    @group = group
    @include_matches = include_matches
  end

  def as_json(*)
    data = {
      id: @group.id,
      name: @group.name,
      completed: @group.completed?,
      standings: standings
    }
    data[:matches] = matches if @include_matches
    data
  end

  private

  # Tabla de posiciones con la posición (1..4) ya asignada.
  def standings
    @group.standings.each_with_index.map do |team, index|
      {
        position: index + 1,
        team: TeamSerializer.new(team).as_json
      }
    end
  end

  def matches
    @group.matches.map { |m| MatchSerializer.new(m).as_json }
  end
end
