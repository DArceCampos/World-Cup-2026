class DashboardController < ApplicationController
  def index
    tournament  = ApiClient.tournament
    all_matches = ApiClient.matches

    total  = all_matches.size
    played = all_matches.count { |m| m["status"] == "played" }
    pending = total - played
    pct     = total > 0 ? (played.to_f / total * 100).round : 0

    @tournament = {
      status:   tournament["status"],
      phase:    phase_display(tournament["status"]),
      played:   played,
      total:    total,
      pending:  pending,
      pct:      pct,
      finished: tournament["status"] == "finished"
    }
    @champion  = team_brief(tournament["champion"])
    @runner_up = team_brief(tournament["runner_up"])
    @third     = team_brief(tournament["third_place"])
  rescue StandardError
    @tournament = { status: "error", phase: "BACKEND NO DISPONIBLE", played: 0,
                    total: 0, pending: 0, pct: 0, finished: false }
    @champion = @runner_up = @third = nil
  end
end
