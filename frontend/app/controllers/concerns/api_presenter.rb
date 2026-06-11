module ApiPresenter
  extend ActiveSupport::Concern

  GROUP_LETTERS = %w[A B C D E F G H I J K L].freeze

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

  ROUND_NAMES = {
    "r32"   => "DIECISEISAVOS",
    "r16"   => "OCTAVOS",
    "qf"    => "CUARTOS",
    "sf"    => "SEMIFINALES",
    "final" => "FINAL"
  }.freeze

  def team_code(name)
    TEAM_CODES[name] || name.to_s[0, 3].upcase
  end

  def group_letter(group_id)
    GROUP_LETTERS[group_id.to_i - 1] || "?"
  end

  def team_brief(api_team)
    return nil unless api_team
    { code: team_code(api_team["name"]), name: api_team["name"] }
  end

  def build_standings_row(pos, team)
    dg = team["goal_difference"].to_i
    {
      pos: pos, code: team_code(team["name"]), name: team["name"],
      pj: team["matches_played"].to_i,
      g:  team["wins"].to_i,
      e:  team["draws"].to_i,
      p:  team["losses"].to_i,
      gf: team["goals_for"].to_i,
      gc: team["goals_against"].to_i,
      dg_str:    (dg >= 0 ? "+" : "") + dg.to_s,
      dg_color:  dg.positive? ? "#16A34A" : dg.negative? ? "#DC2626" : "#9a9ab5",
      pts:       team["points"].to_i,
      accent:    pos <= 2 ? "#16A34A" : pos == 3 ? "#F59E0B" : "transparent",
      bg:        pos <= 2 ? "rgba(22,163,74,.12)" : pos == 3 ? "rgba(245,158,11,.10)" : "transparent",
      pos_color: pos <= 2 ? "#16A34A" : pos == 3 ? "#F59E0B" : "#6f6f99",
      code_color: pos <= 3 ? "#fff" : "#9a9ab5"
    }
  end

  def build_group(api_group)
    {
      id:        api_group["id"],
      name:      api_group["name"],
      completed: api_group["completed"],
      standings: api_group["standings"].map { |s| build_standings_row(s["position"], s["team"]) },
      matches:   (api_group["matches"] || []).map { |m| build_match(m) }
    }
  end

  def build_match(api_match)
    played     = api_match["status"] == "played"
    home_team  = api_match["home_team"] || { "name" => "POR DEFINIR" }
    away_team  = api_match["away_team"] || { "name" => "POR DEFINIR" }
    phase      = api_match["phase"]

    round_label = if phase == "group"
      "GRUPO #{group_letter(api_match["group_id"])}"
    else
      ROUND_NAMES[phase] || phase.to_s.upcase
    end

    home_goals = played ? api_match["home_goals"].to_i + api_match["home_extra_goals"].to_i : nil
    away_goals = played ? api_match["away_goals"].to_i + api_match["away_extra_goals"].to_i : nil

    pen_text = if played && api_match["home_penalties"].to_i > 0
      "PENALES #{api_match["home_penalties"]}-#{api_match["away_penalties"]}"
    end

    {
      id:          api_match["id"],
      round_label: round_label,
      home:        { code: team_code(home_team["name"]), name: home_team["name"] },
      away:        { code: team_code(away_team["name"]), name: away_team["name"] },
      played:      played,
      home_goals:  home_goals,
      away_goals:  away_goals,
      winner:      nil,
      pen_text:    pen_text
    }
  end

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
      home:         { code: team_code(home_team["name"]), name: home_team["name"] },
      away:         { code: team_code(away_team["name"]), name: away_team["name"] },
      home_goals:   home_goals,
      away_goals:   away_goals,
      home_bg:      home_wins ? "rgba(255,212,0,.12)" : "transparent",
      away_bg:      away_wins ? "rgba(255,212,0,.12)" : "transparent",
      home_color:   away_wins ? "#5a5a78" : "#fff",
      away_color:   home_wins ? "#5a5a78" : "#fff",
      pen_text:     pen_text
    }
  end

  def played_group_matches(groups)
    groups.sum { |g| g["standings"].sum { |s| s["team"]["matches_played"].to_i } } / 2
  end

  # Helper methods for controller code that can't access module constants directly.
  def phase_display(status)
    PHASE_LABELS[status] || status.to_s.upcase
  end

  def group_id_for(letter)
    idx = GROUP_LETTERS.index(letter.to_s.upcase)
    idx ? idx + 1 : nil
  end

  def round_name(phase)
    ROUND_NAMES[phase] || phase.to_s.upcase
  end
end
