# AdminController es el panel de control del torneo. Su función es dar al
# administrador acceso a todas las operaciones de gestión: ver el estado global,
# editar equipos, simular la fase de grupos, simular el torneo completo, reiniciar
# resultados y avanzar a eliminatorias manualmente.
# Eso sí, sin este controlador el administrador tendría que hacer todas esas
# operaciones directamente sobre el backend con herramientas como curl o Postman.
class AdminController < ApplicationController
  # Este método carga todo lo que necesita la vista del panel admin:
  # el estado del torneo, el progreso de partidos de grupo y eliminatorias,
  # y los 48 equipos agrupados por letra de grupo para la grilla de edición.
  def index
    tournament  = ApiClient.tournament
    raw_groups  = ApiClient.groups
    raw_teams   = ApiClient.teams
    all_matches = ApiClient.matches

    # Calculamos el progreso de la fase de grupos y el progreso total del torneo.
    group_played = played_group_matches(raw_groups)
    group_total  = 72
    group_pct    = group_played > 0 ? (group_played.to_f / group_total * 100).round : 0

    total_played = all_matches.count { |m| m["status"] == "played" }
    total_all    = all_matches.size
    total_pct    = total_all > 0 ? (total_played.to_f / total_all * 100).round : 0

    status = tournament["status"]

    # Construimos un diccionario id→nombre de grupo para saber a qué grupo
    # pertenece cada equipo (los equipos vienen con group_id numérico, no letra).
    group_name_by_id = raw_groups.each_with_object({}) { |g, h| h[g["id"]] = g["name"] }

    # Agrupamos los equipos por letra de grupo (A–L) para la grilla del admin.
    # Empezamos con un hash con arrays vacíos para que todas las letras existan
    # incluso si un grupo no tiene equipos todavía.
    teams_by_group = ApiPresenter::GROUP_LETTERS.each_with_object({}) { |l, h| h[l] = [] }
    raw_teams.each do |t|
      letter = group_name_by_id[t["group_id"]]
      next unless letter && teams_by_group.key?(letter)
      teams_by_group[letter] << { id: t["id"], code: t["code"].presence || team_code(t["name"]), name: t["name"] }
    end

    @admin_data = {
      status:        status,
      status_label:  phase_display(status),
      group_played:  group_played,
      group_total:   group_total,
      group_pct:     group_pct,
      # group_done se usa para habilitar o deshabilitar el botón de avanzar a eliminatorias.
      group_done:    group_played >= group_total,
      total_played:  total_played,
      total_all:     total_all,
      total_pct:     total_pct,
      finished:      status == "finished"
    }
    @teams_data = teams_by_group
  rescue StandardError
    # Si el backend falla, mostramos el panel en estado de configuración vacío.
    @admin_data = {
      status: "setup", status_label: "CONFIGURACIÓN",
      group_played: 0, group_total: 72, group_pct: 0, group_done: false,
      total_played: 0, total_all: 72, total_pct: 0, finished: false
    }
    @teams_data = {}
  end

  # Simula todos los partidos de grupo pendientes y luego avanza el torneo.
  # Es el botón "Simular fase grupos" del admin — hace todo de un solo click.
  def simulate
    ApiClient.simulate_groups
    ApiClient.tournament_advance
    redirect_to admin_path, notice: "Fase de grupos simulada. Eliminatorias habilitadas."
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al simular grupos: #{e.message}"
  end

  # Simula el torneo completo desde donde esté hasta que haya un campeón.
  # La función de esto es poder ver rápidamente el resultado final sin tener
  # que simular partido por partido.
  def simulate_tournament
    ApiClient.simulate_tournament
    redirect_to admin_path, notice: "Torneo completo simulado. ¡Ya hay campeón!"
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al simular torneo: #{e.message}"
  end

  # Reinicia todos los resultados del torneo: borra goles, eliminatorias y
  # estadísticas de equipos, volviendo al estado inicial de la fase de grupos.
  # Eso sí, esta es la operación más destructiva del sistema — por eso la vista
  # pide confirmación antes de enviar el formulario.
  def reset_groups
    ApiClient.reset_groups
    redirect_to admin_path, notice: "Fase de grupos reiniciada. Resultados y eliminatorias borrados."
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al reiniciar: #{e.message}"
  end

  # Avanza el torneo a la fase eliminatoria manualmente. Esto construye el bracket
  # de dieciseisavos con los 24 clasificados directos y los 8 mejores terceros.
  def advance_knockout
    ApiClient.tournament_advance
    redirect_to knockout_path, notice: "¡Eliminatorias iniciadas!"
  rescue StandardError => e
    redirect_to admin_path, alert: "Error al avanzar: #{e.message}"
  end

  # Este método actualiza el nombre y/o código de un equipo desde la grilla del admin.
  # Responde con JSON porque la vista lo llama via fetch sin recargar la página.
  def update_team
    ApiClient.update_team(params[:id], { name: params[:name], code: params[:code] })
    render json: { ok: true }
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end

  # Este método restaura todos los equipos a sus nombres y códigos FIFA originales.
  # Es útil cuando el administrador editó equipos para pruebas y quiere volver
  # a los datos reales del torneo. Responde con JSON para que la vista haga
  # location.reload() sin perder el scroll del admin.
  def reset_teams
    ApiClient.reset_teams
    render json: { ok: true }
  rescue StandardError => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end
end
