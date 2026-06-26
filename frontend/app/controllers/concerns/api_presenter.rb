module ApiPresenter
  extend ActiveSupport::Concern

  # Letras de los 12 grupos del torneo, en orden. Se usan para iterar grupos
  # y para convertir IDs de grupo a letras (group_id 1 = "A", 2 = "B", etc.).
  GROUP_LETTERS = %w[A B C D E F G H I J K L].freeze

  # Este hash mapea cada nombre de país a su código FIFA de 3 letras.
  # Se usa como fallback cuando un equipo no tiene código guardado en la BD.
  # Eso sí, desde que se agregó el campo code a la base de datos, este hash
  # solo se usa como respaldo — lo normal es que el código venga de la API.
  TEAM_CODES = {
    "México"                  => "MEX",
    "Sudáfrica"               => "RSA",
    "República de Corea"      => "KOR",
    "Chequia"                 => "CZE",
    "Canadá"                  => "CAN",
    "Bosnia y Herzegovina"    => "BIH",
    "Catar"                   => "QAT",
    "Suiza"                   => "SUI",
    "Brasil"                  => "BRA",
    "Marruecos"               => "MAR",
    "Haití"                   => "HAI",
    "Escocia"                 => "SCO",
    "EE. UU."                 => "USA",
    "Paraguay"                => "PAR",
    "Australia"               => "AUS",
    "Turquía"                 => "TUR",
    "Alemania"                => "GER",
    "Curazao"                 => "CUW",
    "Costa de Marfil"         => "CIV",
    "Ecuador"                 => "ECU",
    "Países Bajos"            => "NED",
    "Japón"                   => "JPN",
    "Suecia"                  => "SWE",
    "Túnez"                   => "TUN",
    "Bélgica"                 => "BEL",
    "Egipto"                  => "EGY",
    "RI de Irán"              => "IRN",
    "Nueva Zelanda"           => "NZL",
    "España"                  => "ESP",
    "Islas de Cabo Verde"     => "CPV",
    "Arabia Saudí"            => "KSA",
    "Uruguay"                 => "URU",
    "Francia"                 => "FRA",
    "Senegal"                 => "SEN",
    "Irak"                    => "IRQ",
    "Noruega"                 => "NOR",
    "Argentina"               => "ARG",
    "Argelia"                 => "ALG",
    "Austria"                 => "AUT",
    "Jordania"                => "JOR",
    "Portugal"                => "POR",
    "RD Congo"                => "COD",
    "Uzbekistán"              => "UZB",
    "Colombia"                => "COL",
    "Inglaterra"              => "ENG",
    "Croacia"                 => "CRO",
    "Ghana"                   => "GHA",
    "Panamá"                  => "PAN"
  }.freeze

  # Mapeo de los estados internos del torneo a etiquetas legibles para mostrar
  # en la interfaz. Sin este hash, habría que repetir el mapeo en cada vista.
  PHASE_LABELS = {
    "setup"       => "CONFIGURACIÓN",
    "group_stage" => "FASE DE GRUPOS",
    "r32"         => "DIECISEISAVOS",
    "r16"         => "OCTAVOS DE FINAL",
    "qf"          => "CUARTOS DE FINAL",
    "sf"          => "SEMIFINALES",
    "final"       => "FINAL",
    "finished"    => "FINALIZADO"
  }.freeze

  # Nombres cortos de las rondas eliminatorias para mostrar en el bracket.
  ROUND_NAMES = {
    "r32"   => "DIECISEISAVOS",
    "r16"   => "OCTAVOS",
    "qf"    => "CUARTOS",
    "sf"    => "SEMIFINALES",
    "final" => "FINAL"
  }.freeze

  # Este método devuelve el código FIFA de un equipo por su nombre. Si no está
  # en el diccionario (por ejemplo, un equipo personalizado), usa las primeras
  # 3 letras del nombre en mayúsculas como fallback.
  def team_code(name)
    TEAM_CODES[name] || name.to_s[0, 3].upcase
  end

  # Convierte un ID de grupo numérico a su letra correspondiente.
  # El ID 1 corresponde al índice 0 del array, que es "A".
  def group_letter(group_id)
    GROUP_LETTERS[group_id.to_i - 1] || "?"
  end

  # Este método construye el objeto mínimo de un equipo para las vistas.
  # El .presence || fallback garantiza que si el código viene vacío de la API,
  # se use el fallback del diccionario TEAM_CODES.
  def team_brief(api_team)
    return nil unless api_team
    { code: api_team["code"].presence || team_code(api_team["name"]), name: api_team["name"] }
  end

  # Este método construye una fila de la tabla de posiciones con todos los datos
  # que necesita la vista: estadísticas, colores según posición y formato del DG.
  # Eso sí, sin este método cada vista que muestre standings tendría que calcular
  # los colores y formatos por separado.
  def build_standings_row(pos, team)
    dg = team["goal_difference"].to_i
    {
      pos:      pos,
      code:     team["code"].presence || team_code(team["name"]),
      name:     team["name"],
      pj:       team["matches_played"].to_i,
      g:        team["wins"].to_i,
      e:        team["draws"].to_i,
      p:        team["losses"].to_i,
      gf:       team["goals_for"].to_i,
      gc:       team["goals_against"].to_i,
      # El signo + se agrega manualmente a la diferencia positiva.
      dg_str:    (dg >= 0 ? "+" : "") + dg.to_s,
      # Verde si DG positivo, rojo si negativo, gris si cero.
      dg_color:  dg.positive? ? "#16A34A" : dg.negative? ? "#DC2626" : "#9a9ab5",
      pts:       team["points"].to_i,
      # Los primeros dos clasifican (verde), el tercero es candidato a mejor tercero (naranja).
      accent:    pos <= 2 ? "#16A34A" : pos == 3 ? "#F59E0B" : "transparent",
      bg:        pos <= 2 ? "rgba(22,163,74,.12)" : pos == 3 ? "rgba(245,158,11,.10)" : "transparent",
      pos_color: pos <= 2 ? "#16A34A" : pos == 3 ? "#F59E0B" : "#6f6f99",
      code_color: pos <= 3 ? "#fff" : "#9a9ab5"
    }
  end

  # Este método transforma un grupo de la API en el hash que necesitan las vistas.
  # Construye las posiciones y los partidos usando los métodos auxiliares del concern.
  def build_group(api_group)
    {
      id:        api_group["id"],
      name:      api_group["name"],
      completed: api_group["completed"],
      standings: api_group["standings"].map { |s| build_standings_row(s["position"], s["team"]) },
      matches:   (api_group["matches"] || []).map { |m| build_match(m) }
    }
  end

  # Este método transforma un partido de la API en el hash que necesita la
  # vista de partidos de grupo. Calcula el total de goles, el texto de penales
  # y la etiqueta de la ronda (GRUPO A, OCTAVOS, etc.).
  def build_match(api_match)
    played    = api_match["status"] == "played"
    home_team = api_match["home_team"] || { "name" => "POR DEFINIR" }
    away_team = api_match["away_team"] || { "name" => "POR DEFINIR" }
    phase     = api_match["phase"]

    # La etiqueta de la ronda es diferente para grupos vs. eliminatorias.
    round_label = if phase == "group"
      "GRUPO #{group_letter(api_match["group_id"])}"
    else
      ROUND_NAMES[phase] || phase.to_s.upcase
    end

    # Los goles mostrados suman tiempo reglamentario + prórroga.
    home_goals = played ? api_match["home_goals"].to_i + api_match["home_extra_goals"].to_i : nil
    away_goals = played ? api_match["away_goals"].to_i + api_match["away_extra_goals"].to_i : nil

    # Si hubo penales, se construye el texto "PENALES 4-3" para mostrarlo.
    pen_text = if played && api_match["home_penalties"].to_i > 0
      "PENALES #{api_match["home_penalties"]}-#{api_match["away_penalties"]}"
    end

    {
      id:          api_match["id"],
      round_label: round_label,
      home:        { code: home_team["code"].presence || team_code(home_team["name"]), name: home_team["name"] },
      away:        { code: away_team["code"].presence || team_code(away_team["name"]), name: away_team["name"] },
      played:      played,
      home_goals:  home_goals,
      away_goals:  away_goals,
      winner:      nil,
      pen_text:    pen_text
    }
  end

  # Este método transforma un partido eliminatorio en el hash para el bracket.
  # A diferencia de build_match, este calcula los colores de resaltado según
  # quién ganó, para mostrar al ganador destacado y al perdedor en gris.
  def build_bracket_match(api_match)
    played    = api_match["status"] == "played"
    home_team = api_match["home_team"] || { "id" => nil, "name" => "POR DEFINIR" }
    away_team = api_match["away_team"] || { "id" => nil, "name" => "POR DEFINIR" }
    winner_id = api_match["winner"]&.dig("id")

    home_goals = played ? api_match["home_goals"].to_i + api_match["home_extra_goals"].to_i : nil
    away_goals = played ? api_match["away_goals"].to_i + api_match["away_extra_goals"].to_i : nil

    pen_text = if played && api_match["home_penalties"].to_i > 0
      "PENALES #{api_match["home_penalties"]}-#{api_match["away_penalties"]}"
    end

    home_wins = winner_id && winner_id == home_team["id"]
    away_wins = winner_id && winner_id == away_team["id"]

    {
      id:           api_match["id"],
      phase:        api_match["phase"],
      round_number: api_match["round_number"],
      played:       played,
      home:         { code: home_team["code"].presence || team_code(home_team["name"]), name: home_team["name"] },
      away:         { code: away_team["code"].presence || team_code(away_team["name"]), name: away_team["name"] },
      home_goals:   home_goals,
      away_goals:   away_goals,
      # El ganador se resalta en dorado, el perdedor se opaca en gris.
      home_bg:      home_wins ? "rgba(255,212,0,.12)" : "transparent",
      away_bg:      away_wins ? "rgba(255,212,0,.12)" : "transparent",
      home_color:   away_wins ? "#5a5a78" : "#fff",
      away_color:   home_wins ? "#5a5a78" : "#fff",
      pen_text:     pen_text
    }
  end

  # Este método cuenta cuántos partidos de grupo se han jugado en total.
  # Suma los partidos jugados de todos los equipos y divide entre 2 porque
  # cada partido cuenta para dos equipos (local y visitante).
  def played_group_matches(groups)
    groups.sum { |g| g["standings"].sum { |s| s["team"]["matches_played"].to_i } } / 2
  end

  # Convierte un status interno como "group_stage" a su etiqueta legible.
  def phase_display(status)
    PHASE_LABELS[status] || status.to_s.upcase
  end

  # Convierte una letra de grupo a su ID numérico (inverso de group_letter).
  def group_id_for(letter)
    idx = GROUP_LETTERS.index(letter.to_s.upcase)
    idx ? idx + 1 : nil
  end

  # Convierte una fase interna como "r16" a su nombre legible "OCTAVOS".
  def round_name(phase)
    ROUND_NAMES[phase] || phase.to_s.upcase
  end
end
