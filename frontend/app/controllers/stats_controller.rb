# StatsController genera los datos de estadísticas del torneo para la vista.
# Su función principal es construir dos estructuras de datos: los acumulados
# por equipo (partidos, goles, puntos) y los datos de cada partido jugado
# (para la tabla de resultados). Luego los serializa a JSON y los pasa a la
# vista en @stats_data, donde JavaScript los usa para renderizar las gráficas.
# Eso sí, sin este controlador la vista de stats recibiría datos brutos sin
# procesar y el JS tendría que hacer toda la lógica de cálculo en el browser.
class StatsController < ApplicationController
  # Etiquetas cortas para cada fase, pensadas para columnas angostas en la tabla.
  PHASE_LABELS_SHORT = {
    "group" => "GRUPO", "r32" => "16AVOS", "r16" => "8VOS",
    "qf" => "4TOS", "sf" => "SEMI", "3rd" => "3ER", "final" => "FINAL"
  }.freeze

  def index
    raw_groups  = ApiClient.groups
    all_matches = ApiClient.matches

    # Construimos un diccionario id→nombre de grupo para etiquetar los partidos
    # de grupo con "GRUPO A", "GRUPO B", etc. en vez de el ID numérico.
    group_name_by_id = raw_groups.each_with_object({}) { |g, h| h[g["id"]] = g["name"] }

    # Inicializamos la estructura de stats por equipo desde los standings de grupo.
    # Empezamos con ceros porque los partidos eliminatorios también se acumularán.
    team_stats = {}
    raw_groups.each do |g|
      g["standings"].each do |s|
        t = s["team"]
        team_stats[t["name"]] = {
          code: team_code(t["name"]), name: t["name"], group: g["name"],
          pos: s["position"], pj: 0, pts: 0, gf: 0, gc: 0, dg: 0, g: 0, e: 0, p: 0
        }
      end
    end

    # Solo procesamos los partidos que ya se jugaron — los pendientes no tienen goles.
    played_matches = all_matches.select { |m| m["status"] == "played" }

    # Este bucle acumula los goles y puntos de cada partido para ambos equipos.
    # Los goles de prórroga se suman a los del tiempo reglamentario porque al
    # usuario le interesa el total, no el desglose por tiempo.
    played_matches.each do |m|
      ht = m.dig("home_team", "name").to_s
      at = m.dig("away_team", "name").to_s
      hg = m["home_goals"].to_i + m["home_extra_goals"].to_i
      ag = m["away_goals"].to_i + m["away_extra_goals"].to_i

      # Si un equipo eliminatorio no estaba en los standings de grupo (no debería pasar),
      # lo inicializamos con ceros para evitar un nil error.
      [ht, at].each do |name|
        team_stats[name] ||= { code: team_code(name), name: name, group: "?", pos: 0,
                                pj: 0, pts: 0, gf: 0, gc: 0, dg: 0, g: 0, e: 0, p: 0 }
      end

      home = team_stats[ht]
      away = team_stats[at]

      home[:pj] += 1; away[:pj] += 1
      home[:gf] += hg; home[:gc] += ag
      away[:gf] += ag; away[:gc] += hg

      # Determinamos victoria, derrota o empate y asignamos los puntos
      # del partido (3 al ganador, 1 a cada uno en empate).
      if hg > ag
        home[:g] += 1; home[:pts] += 3
        away[:p] += 1
      elsif ag > hg
        away[:g] += 1; away[:pts] += 3
        home[:p] += 1
      else
        home[:e] += 1; away[:e] += 1
        home[:pts] += 1; away[:pts] += 1
      end
    end

    # La diferencia de goles se calcula al final, una sola vez, en vez de
    # actualizarla en cada iteración del bucle anterior.
    team_stats.each_value { |t| t[:dg] = t[:gf] - t[:gc] }
    teams_data = team_stats.values

    # Este array transforma cada partido jugado en el formato que necesita el
    # JavaScript de la vista para renderizar la tabla de resultados.
    matches_data = played_matches.map do |m|
      ht = m["home_team"] || {}
      at = m["away_team"] || {}
      hg = m["home_goals"].to_i + m["home_extra_goals"].to_i
      ag = m["away_goals"].to_i + m["away_extra_goals"].to_i
      phase = m["phase"].to_s
      # La etiqueta de fase es diferente para grupos (incluye la letra del grupo)
      # vs. eliminatorias (usa la etiqueta corta del hash PHASE_LABELS_SHORT).
      phase_label = if phase == "group"
        "GRUPO #{group_name_by_id[m["group_id"]] || "?"}"
      else
        PHASE_LABELS_SHORT[phase] || phase.upcase
      end
      {
        home_code: team_code(ht["name"].to_s),
        away_code: team_code(at["name"].to_s),
        hg: hg, ag: ag,
        phase: phase_label,
        # diff es el margen de victoria; se usa para ordenar los partidos más disputados.
        diff: (hg - ag).abs
      }
    end

    # Todo se serializa a JSON porque la vista lo consume directo con JavaScript.
    @stats_data = { teams: teams_data, matches: matches_data }.to_json
  rescue StandardError
    @stats_data = { teams: [], matches: [] }.to_json
  end
end
