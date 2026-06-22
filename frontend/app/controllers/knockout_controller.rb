class KnockoutController < ApplicationController
  TOTAL_GROUP_MATCHES = 72

  def index
    tournament = ApiClient.tournament

    if tournament["status"] == "group_stage" || tournament["status"] == "setup"
      groups     = ApiClient.groups
      played     = played_group_matches(groups)
      @locked    = true
      @remaining = TOTAL_GROUP_MATCHES - played
      @rounds    = []
      @champion  = nil
      @runner_up = nil
      @third     = nil
    else
      data      = ApiClient.knockout_bracket
      rounds    = data["rounds"] || []

      third_round    = rounds.find { |r| r["phase"] == "3rd" }
      bracket_rounds = rounds.reject { |r| r["phase"] == "3rd" }

      @locked    = false
      @rounds    = bracket_rounds.map do |r|
        {
          name:    round_name(r["phase"]),
          matches: r["matches"].map { |m| build_bracket_match(m) }
        }
      end

      @champion  = team_brief(tournament["champion"])
      @runner_up = team_brief(tournament["runner_up"])

      @third = if third_round && (tm = third_round["matches"].first)
        build_bracket_match(tm)
      end
    end
  rescue StandardError
    @locked    = true
    @remaining = TOTAL_GROUP_MATCHES
    @rounds    = []
    @champion  = nil
    @runner_up = nil
    @third     = nil
  end

  def simulate
    ApiClient.simulate_match(params[:id])
    ApiClient.tournament_advance
    render json: { ok: true }
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end

  def result
    goals = {
      home_goals:       params[:home_goals].to_i,
      away_goals:       params[:away_goals].to_i,
      home_extra_goals: 0,
      away_extra_goals: 0,
      home_penalties:   params[:home_penalties].to_i,
      away_penalties:   params[:away_penalties].to_i
    }
    ApiClient.record_result(params[:id], goals)
    ApiClient.tournament_advance
    render json: { ok: true }
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end
end
