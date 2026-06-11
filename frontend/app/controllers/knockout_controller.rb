class KnockoutController < ApplicationController
  TOTAL_GROUP_MATCHES = 72

  def index
    tournament = ApiClient.tournament

    if tournament["status"] == "group_stage" || tournament["status"] == "setup"
      groups    = ApiClient.groups
      played    = played_group_matches(groups)
      @locked   = true
      @remaining = TOTAL_GROUP_MATCHES - played
      @rounds    = []
      @champion  = nil
      @third     = nil
    else
      data      = ApiClient.knockout_bracket
      rounds    = data["rounds"] || []

      third_round    = rounds.find { |r| r["phase"] == "3rd" }
      bracket_rounds = rounds.reject { |r| r["phase"] == "3rd" }

      @locked  = false
      @rounds  = bracket_rounds.map do |r|
        {
          name:    round_name(r["phase"]),
          matches: r["matches"].map { |m| build_bracket_match(m) }
        }
      end

      @champion = team_brief(tournament["champion"])

      @third = if third_round && (tm = third_round["matches"].first)
        build_bracket_match(tm)
      end
    end
  rescue StandardError
    @locked    = true
    @remaining = TOTAL_GROUP_MATCHES
    @rounds    = []
    @champion  = nil
    @third     = nil
  end
end
