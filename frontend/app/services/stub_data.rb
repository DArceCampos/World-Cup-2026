module StubData
  GROUPS = ["A","B","C","D","E","F","G","H","I","J","K","L"].freeze

  TEAMS = {
    "A" => [["MEX","México"],["RSA","Sudáfrica"],["KOR","Rep. de Corea"],["CZE","Chequia"]],
    "B" => [["CAN","Canadá"],["BIH","Bosnia y Herz."],["QAT","Catar"],["SUI","Suiza"]],
    "C" => [["BRA","Brasil"],["MAR","Marruecos"],["HAI","Haití"],["SCO","Escocia"]],
    "D" => [["USA","EE. UU."],["PAR","Paraguay"],["AUS","Australia"],["TUR","Turquía"]],
    "E" => [["GER","Alemania"],["CUW","Curazao"],["CIV","Costa de Marfil"],["ECU","Ecuador"]],
    "F" => [["NED","Países Bajos"],["JPN","Japón"],["SWE","Suecia"],["TUN","Túnez"]],
    "G" => [["BEL","Bélgica"],["EGY","Egipto"],["IRN","RI de Irán"],["NZL","Nueva Zelanda"]],
    "H" => [["ESP","España"],["CPV","Cabo Verde"],["KSA","Arabia Saudí"],["URU","Uruguay"]],
    "I" => [["FRA","Francia"],["SEN","Senegal"],["IRQ","Irak"],["NOR","Noruega"]],
    "J" => [["ARG","Argentina"],["ALG","Argelia"],["AUT","Austria"],["JOR","Jordania"]],
    "K" => [["POR","Portugal"],["COD","RD Congo"],["UZB","Uzbekistán"],["COL","Colombia"]],
    "L" => [["ENG","Inglaterra"],["CRO","Croacia"],["GHA","Ghana"],["PAN","Panamá"]]
  }.freeze

  PAIRS = [[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]].freeze

  def self.tournament
    { status: "group_stage", phase: "FASE DE GRUPOS", played: 0, total: 72, pending: 72, pct: 0, finished: false }
  end

  def self.all_groups
    GROUPS.map.with_index(1) do |letter, idx|
      { id: idx, name: letter, standings: standings_for(letter), matches: matches_for(letter, idx), completed: false }
    end
  end

  def self.find_group(letter)
    idx = GROUPS.index(letter.upcase)
    return nil unless idx
    id = idx + 1
    { id: id, name: letter.upcase, standings: standings_for(letter.upcase), matches: matches_for(letter.upcase, id), completed: false }
  end

  def self.all_matches(group_filter: nil, status_filter: nil)
    GROUPS.flat_map.with_index(1) do |letter, group_id|
      next [] if group_filter && group_filter != letter
      matches_for(letter, group_id)
    end.then do |list|
      case status_filter
      when "scheduled" then list.select { |m| !m[:played] }
      when "played"    then list.select { |m| m[:played] }
      else list
      end
    end
  end

  def self.standings_for(letter)
    TEAMS[letter].each_with_index.map do |(code, name), i|
      row(i + 1, code, name)
    end
  end

  def self.matches_for(letter, group_id)
    teams = TEAMS[letter]
    base_id = (GROUPS.index(letter)) * 6
    PAIRS.each_with_index.map do |(hi, ai), i|
      {
        id: base_id + i + 1,
        group_id: group_id,
        round_label: "GRUPO #{letter}",
        home: { code: teams[hi][0], name: teams[hi][1] },
        away: { code: teams[ai][0], name: teams[ai][1] },
        played: false,
        home_goals: nil,
        away_goals: nil,
        home_extra_goals: nil,
        away_extra_goals: nil,
        home_penalties: nil,
        away_penalties: nil,
        winner: nil,
        pen_text: nil
      }
    end
  end

  def self.row(pos, code, name, pj=0, g=0, e=0, p=0, gf=0, gc=0, pts=0)
    dg = gf - gc
    {
      pos: pos, code: code, name: name,
      pj: pj, g: g, e: e, p: p, gf: gf, gc: gc,
      dg_str: (dg >= 0 ? "+" : "") + dg.to_s,
      dg_color: dg > 0 ? "#16A34A" : dg < 0 ? "#DC2626" : "#9a9ab5",
      pts: pts,
      accent:    pos <= 2 ? "#16A34A" : pos == 3 ? "#F59E0B" : "transparent",
      bg:        pos <= 2 ? "rgba(22,163,74,.12)" : pos == 3 ? "rgba(245,158,11,.10)" : "transparent",
      pos_color: pos <= 2 ? "#16A34A" : pos == 3 ? "#F59E0B" : "#6f6f99",
      code_color: pos <= 4 ? (pos <= 2 || pos == 3 ? "#fff" : "#9a9ab5") : "#9a9ab5"
    }
  end
end
