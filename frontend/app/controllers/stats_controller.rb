class StatsController < ApplicationController
  def index
    raw_groups  = ApiClient.groups
    all_matches = ApiClient.matches(phase: "group")

    group_name_by_id = raw_groups.each_with_object({}) { |g, h| h[g["id"]] = g["name"] }

    teams_data = raw_groups.flat_map do |g|
      g["standings"].map do |s|
        t  = s["team"]
        dg = t["goal_difference"].to_i
        {
          code:  team_code(t["name"]),
          name:  t["name"],
          group: g["name"],
          pos:   s["position"],
          pj:    t["matches_played"].to_i,
          pts:   t["points"].to_i,
          gf:    t["goals_for"].to_i,
          gc:    t["goals_against"].to_i,
          dg:    dg,
          g:     t["wins"].to_i,
          e:     t["draws"].to_i,
          p:     t["losses"].to_i
        }
      end
    end

    matches_data = all_matches.select { |m| m["status"] == "played" }.map do |m|
      ht = m["home_team"] || {}
      at = m["away_team"] || {}
      hg = m["home_goals"].to_i + m["home_extra_goals"].to_i
      ag = m["away_goals"].to_i + m["away_extra_goals"].to_i
      {
        home_code: team_code(ht["name"].to_s),
        away_code: team_code(at["name"].to_s),
        hg:        hg,
        ag:        ag,
        group:     group_name_by_id[m["group_id"]] || "?",
        diff:      (hg - ag).abs
      }
    end

    @stats_data = { teams: teams_data, matches: matches_data }.to_json
  rescue StandardError
    @stats_data = { teams: [], matches: [] }.to_json
  end
end
