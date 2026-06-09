# MatchSerializer — convierte un Match en un hash JSON, incluyendo el
# ganador calculado y el marcador completo (goles, prórroga, penales).
class MatchSerializer
  def initialize(match)
    @match = match
  end

  def as_json(*)
    {
      id: @match.id,
      phase: @match.phase,
      group_id: @match.group_id,
      round_number: @match.round_number,
      status: @match.status,
      home_team: TeamSerializer.brief(@match.home_team),
      away_team: TeamSerializer.brief(@match.away_team),
      home_goals: @match.home_goals,
      away_goals: @match.away_goals,
      home_extra_goals: @match.home_extra_goals,
      away_extra_goals: @match.away_extra_goals,
      home_penalties: @match.home_penalties,
      away_penalties: @match.away_penalties,
      winner: TeamSerializer.brief(@match.winner)
    }
  end
end
