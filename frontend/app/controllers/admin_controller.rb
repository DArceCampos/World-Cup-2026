class AdminController < ApplicationController
  def index
    tournament = ApiClient.tournament
    raw_groups = ApiClient.groups
    raw_teams  = ApiClient.teams

    played = played_group_matches(raw_groups)
    total  = 72
    pct    = played > 0 ? (played.to_f / total * 100).round : 0
    done   = played >= total

    group_name_by_id = raw_groups.each_with_object({}) { |g, h| h[g["id"]] = g["name"] }

    teams_by_group = ApiPresenter::GROUP_LETTERS.each_with_object({}) { |l, h| h[l] = [] }
    raw_teams.each do |t|
      letter = group_name_by_id[t["group_id"]]
      next unless letter && teams_by_group.key?(letter)
      teams_by_group[letter] << { id: t["id"], code: team_code(t["name"]), name: t["name"] }
    end

    @admin_data = {
      status:  tournament["status"],
      played:  played,
      total:   total,
      pending: total - played,
      pct:     pct,
      done:    done
    }
    @teams_data = teams_by_group
  rescue StandardError
    @admin_data = { status: "setup", played: 0, total: 72, pending: 72, pct: 0, done: false }
    @teams_data = {}
  end

  def simulate
    ApiClient.simulate_groups
    ApiClient.tournament_advance
    redirect_to admin_path, notice: "Simulación ejecutada. Fase eliminatoria habilitada."
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al simular: #{e.message}"
  end

  def reset_groups
    ApiClient.reset_groups
    redirect_to admin_path, notice: "Fase de grupos reiniciada. Resultados y eliminatorias borrados."
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al reiniciar: #{e.message}"
  end

  def update_team
    result = ApiClient.update_team(params[:id], { name: params[:name] })
    render json: { ok: true }
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end
end
