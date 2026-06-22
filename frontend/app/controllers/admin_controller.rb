class AdminController < ApplicationController
  def index
    tournament = ApiClient.tournament
    raw_groups = ApiClient.groups
    raw_teams  = ApiClient.teams
    all_matches = ApiClient.matches

    group_played = played_group_matches(raw_groups)
    group_total  = 72
    group_pct    = group_played > 0 ? (group_played.to_f / group_total * 100).round : 0

    total_played = all_matches.count { |m| m["status"] == "played" }
    total_all    = all_matches.size
    total_pct    = total_all > 0 ? (total_played.to_f / total_all * 100).round : 0

    status = tournament["status"]

    group_name_by_id = raw_groups.each_with_object({}) { |g, h| h[g["id"]] = g["name"] }

    teams_by_group = ApiPresenter::GROUP_LETTERS.each_with_object({}) { |l, h| h[l] = [] }
    raw_teams.each do |t|
      letter = group_name_by_id[t["group_id"]]
      next unless letter && teams_by_group.key?(letter)
      teams_by_group[letter] << { id: t["id"], code: team_code(t["name"]), name: t["name"] }
    end

    @admin_data = {
      status:        status,
      status_label:  phase_display(status),
      group_played:  group_played,
      group_total:   group_total,
      group_pct:     group_pct,
      group_done:    group_played >= group_total,
      total_played:  total_played,
      total_all:     total_all,
      total_pct:     total_pct,
      finished:      status == "finished"
    }
    @teams_data = teams_by_group
  rescue StandardError
    @admin_data = {
      status: "setup", status_label: "CONFIGURACIÓN",
      group_played: 0, group_total: 72, group_pct: 0, group_done: false,
      total_played: 0, total_all: 72, total_pct: 0, finished: false
    }
    @teams_data = {}
  end

  def simulate
    ApiClient.simulate_groups
    ApiClient.tournament_advance
    redirect_to admin_path, notice: "Fase de grupos simulada. Eliminatorias habilitadas."
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al simular grupos: #{e.message}"
  end

  def simulate_tournament
    ApiClient.simulate_tournament
    redirect_to admin_path, notice: "Torneo completo simulado. ¡Ya hay campeón!"
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al simular torneo: #{e.message}"
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
