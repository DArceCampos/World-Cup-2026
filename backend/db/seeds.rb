# Seeds — carga inicial de la Copa Mundial FIFA 2026.
#
# Crea el torneo, los 12 grupos (A–L), las 48 selecciones (4 por grupo) y el
# fixture de fase de grupos (round-robin: 6 partidos por grupo, cada equipo
# juega 3). Es idempotente: limpia los datos previos antes de cargar.

puts "Limpiando datos previos..."
Match.delete_all
Team.delete_all
Group.delete_all
Tournament.delete_all

puts "Creando torneo..."
tournament = Tournament.create!(name: "Copa Mundial FIFA 2026", status: "group_stage")

# 48 selecciones distribuidas en 12 grupos de 4.
TEAMS_BY_GROUP = {
  "A" => ["México", "Canadá", "Croacia", "Ghana"],
  "B" => ["Estados Unidos", "Inglaterra", "Senegal", "Corea del Sur"],
  "C" => ["Argentina", "Polonia", "Marruecos", "Arabia Saudita"],
  "D" => ["Francia", "Dinamarca", "Australia", "Túnez"],
  "E" => ["España", "Alemania", "Japón", "Costa Rica"],
  "F" => ["Brasil", "Suiza", "Camerún", "Serbia"],
  "G" => ["Portugal", "Uruguay", "Corea del Norte", "Qatar"],
  "H" => ["Bélgica", "Países Bajos", "Ecuador", "Irán"],
  "I" => ["Italia", "Colombia", "Nigeria", "Nueva Zelanda"],
  "J" => ["Inglaterra B", "Egipto", "Perú", "Jamaica"],
  "K" => ["Países Bajos B", "Chile", "Argelia", "Honduras"],
  "L" => ["Croacia B", "Costa de Marfil", "Paraguay", "Panamá"]
}.freeze

puts "Creando grupos, equipos y fixture..."
TEAMS_BY_GROUP.each do |group_name, team_names|
  group = Group.create!(name: group_name, tournament: tournament)

  teams = team_names.map do |team_name|
    Team.create!(name: team_name, group: group)
  end

  # Round-robin: todas las combinaciones de 2 equipos (6 partidos).
  teams.combination(2).each do |home, away|
    Match.create!(
      tournament: tournament,
      group: group,
      home_team: home,
      away_team: away,
      phase: "group",
      status: "scheduled"
    )
  end
end

puts "Listo:"
puts "  Grupos:   #{Group.count}"
puts "  Equipos:  #{Team.count}"
puts "  Partidos: #{Match.count} (fase de grupos)"
