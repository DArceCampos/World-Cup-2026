class GroupsController < ApplicationController
  def index
    raw_groups   = ApiClient.groups
    @groups      = raw_groups.map { |g| build_group(g) }
    @best_thirds = compute_best_thirds(raw_groups)
  rescue StandardError
    @groups      = []
    @best_thirds = []
  end

  def show
    api_group = ApiClient.group(params[:id])
    redirect_to groups_path and return unless api_group
    @group = build_group(api_group)
  rescue StandardError
    redirect_to groups_path
  end

  private

  def compute_best_thirds(raw_groups)
    thirds = raw_groups.filter_map do |g|
      s = g["standings"].find { |st| st["position"] == 3 }
      next unless s
      t  = s["team"]
      dg = t["goal_difference"].to_i
      {
        code:    team_code(t["name"]),
        name:    t["name"],
        group:   g["name"],
        pj:      t["matches_played"].to_i,
        pts:     t["points"].to_i,
        gf:      t["goals_for"].to_i,
        gc:      t["goals_against"].to_i,
        dg:      dg,
        dg_str:  (dg >= 0 ? "+" : "") + dg.to_s,
        g:       t["wins"].to_i,
        e:       t["draws"].to_i,
        p:       t["losses"].to_i
      }
    end

    thirds.sort_by { |t| [-t[:pts], -t[:dg], -t[:gf]] }
  end
end
