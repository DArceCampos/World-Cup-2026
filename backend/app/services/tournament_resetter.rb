class TournamentResetter
  def initialize(tournament)
    @tournament = tournament
  end

  def reset_groups!
    ActiveRecord::Base.transaction do
      @tournament.matches.knockout.delete_all

      @tournament.matches.group_phase.update_all(
        status:           "scheduled",
        home_goals:       0,
        away_goals:       0,
        home_extra_goals: 0,
        away_extra_goals: 0,
        home_penalties:   0,
        away_penalties:   0
      )

      @tournament.teams.update_all(
        matches_played:  0,
        wins:            0,
        draws:           0,
        losses:          0,
        goals_for:       0,
        goals_against:   0,
        goal_difference: 0,
        points:          0
      )

      @tournament.update!(status: "group_stage")
    end
  end
end
