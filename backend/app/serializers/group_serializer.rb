# GroupSerializer convierte un objeto Group en un hash JSON para la API.
# Su función es armar la tabla de posiciones ya ordenada y, opcionalmente,
# incluir los partidos del grupo. Se usa con include_matches: false para el
# listado general (solo posiciones) y con include_matches: true para el
# detalle de un grupo específico.
class GroupSerializer
  # El parámetro include_matches controla si se incluyen los partidos en la
  # respuesta. Esto evita enviar datos innecesarios cuando solo se necesita
  # la tabla de posiciones.
  def initialize(group, include_matches: false)
    @group = group
    @include_matches = include_matches
  end

  # Este método lo que hace es construir el hash del grupo con su estado
  # (completado o no) y su tabla de posiciones. Si se pidió con partidos,
  # los agrega al final. La lógica condicional en data[:matches] evita
  # hacer la consulta SQL de partidos cuando no se necesitan.
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

  # Este método privado lo que hace es convertir la tabla de posiciones del
  # grupo en un array con posición numérica (1, 2, 3, 4) ya asignada.
  # Usa each_with_index para saber qué posición le corresponde a cada equipo
  # después de que standings los ordena por criterio FIFA.
  def standings
    @group.standings.each_with_index.map do |team, index|
      {
        position: index + 1,
        team: TeamSerializer.new(team).as_json
      }
    end
  end

  # Este método privado serializa cada partido del grupo usando MatchSerializer.
  # Solo se llama si include_matches: true fue pasado al constructor.
  def matches
    @group.matches.map { |m| MatchSerializer.new(m).as_json }
  end
end
