class StatsController < ApplicationController
  PHASE_LABELS_SHORT = {
    "group" => "GRUPO", "r32" => "16AVOS", "r16" => "8VOS",
    "qf" => "4TOS", "sf" => "SEMI", "3rd" => "3ER", "final" => "FINAL"
  }.freeze

  def index
    raw_groups  = ApiClient.groups
    all_matches = ApiClient.matches

    group_name_by_id = raw_groups.each_with_object({}) { |g, h| h[g["id"]] = g["name"] }

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

    played_matches = all_matches.select { |m| m["status"] == "played" }

    played_matches.each do |m|
      ht = m.dig("home_team", "name").to_s
      at = m.dig("away_team", "name").to_s
      hg = m["home_goals"].to_i + m["home_extra_goals"].to_i
      ag = m["away_goals"].to_i + m["away_extra_goals"].to_i

      [ht, at].each do |name|
        team_stats[name] ||= { code: team_code(name), name: name, group: "?", pos: 0,
                                pj: 0, pts: 0, gf: 0, gc: 0, dg: 0, g: 0, e: 0, p: 0 }
      end

      home = team_stats[ht]
      away = team_stats[at]

      home[:pj] += 1; away[:pj] += 1
      home[:gf] += hg; home[:gc] += ag
      away[:gf] += ag; away[:gc] += hg

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

    team_stats.each_value { |t| t[:dg] = t[:gf] - t[:gc] }
    teams_data = team_stats.values

    matches_data = played_matches.map do |m|
      ht = m["home_team"] || {}
      at = m["away_team"] || {}
      hg = m["home_goals"].to_i + m["home_extra_goals"].to_i
      ag = m["away_goals"].to_i + m["away_extra_goals"].to_i
      phase = m["phase"].to_s
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
        diff: (hg - ag).abs
      }
    end

    @stats_data = { teams: teams_data, matches: matches_data }.to_json
  rescue StandardError
    @stats_data = { teams: [], matches: [] }.to_json
  end
end
