class DashboardController < ApplicationController
  TOTAL_GROUP_MATCHES = 72

  def index
    tournament = ApiClient.tournament
    groups     = ApiClient.groups

    played  = played_group_matches(groups)
    pending = TOTAL_GROUP_MATCHES - played
    pct     = (played.to_f / TOTAL_GROUP_MATCHES * 100).round

    @tournament = {
      status:   tournament["status"],
      phase:    phase_display(tournament["status"]),
      played:   played,
      total:    TOTAL_GROUP_MATCHES,
      pending:  pending,
      pct:      pct,
      finished: tournament["status"] == "finished"
    }
    @champion  = team_brief(tournament["champion"])
    @runner_up = team_brief(tournament["runner_up"])
    @third     = team_brief(tournament["third_place"])
  rescue StandardError
    @tournament = { status: "error", phase: "BACKEND NO DISPONIBLE", played: 0,
                    total: TOTAL_GROUP_MATCHES, pending: TOTAL_GROUP_MATCHES, pct: 0, finished: false }
    @champion = @runner_up = @third = nil
  end
end
