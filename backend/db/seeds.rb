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

# 48 selecciones distribuidas en 12 grupos de 4: [nombre, código FIFA].
TEAMS_BY_GROUP = {
  "A" => [["México","MEX"],["Sudáfrica","RSA"],["República de Corea","KOR"],["Chequia","CZE"]],
  "B" => [["Canadá","CAN"],["Bosnia y Herzegovina","BIH"],["Catar","QAT"],["Suiza","SUI"]],
  "C" => [["Brasil","BRA"],["Marruecos","MAR"],["Haití","HAI"],["Escocia","SCO"]],
  "D" => [["EE. UU.","USA"],["Paraguay","PAR"],["Australia","AUS"],["Turquía","TUR"]],
  "E" => [["Alemania","GER"],["Curazao","CUW"],["Costa de Marfil","CIV"],["Ecuador","ECU"]],
  "F" => [["Países Bajos","NED"],["Japón","JPN"],["Suecia","SWE"],["Túnez","TUN"]],
  "G" => [["Bélgica","BEL"],["Egipto","EGY"],["RI de Irán","IRN"],["Nueva Zelanda","NZL"]],
  "H" => [["España","ESP"],["Islas de Cabo Verde","CPV"],["Arabia Saudí","KSA"],["Uruguay","URU"]],
  "I" => [["Francia","FRA"],["Senegal","SEN"],["Irak","IRQ"],["Noruega","NOR"]],
  "J" => [["Argentina","ARG"],["Argelia","ALG"],["Austria","AUT"],["Jordania","JOR"]],
  "K" => [["Portugal","POR"],["RD Congo","COD"],["Uzbekistán","UZB"],["Colombia","COL"]],
  "L" => [["Inglaterra","ENG"],["Croacia","CRO"],["Ghana","GHA"],["Panamá","PAN"]]
}.freeze

puts "Creando grupos, equipos y fixture..."
TEAMS_BY_GROUP.each do |group_name, team_entries|
  group = Group.create!(name: group_name, tournament: tournament)

  teams = team_entries.map do |team_name, team_code|
    Team.create!(name: team_name, code: team_code, group: group)
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
