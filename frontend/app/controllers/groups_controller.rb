# GroupsController maneja la vista de grupos del torneo. Tiene tres acciones:
# index (todos los grupos + tabla de mejores terceros), show (un grupo en detalle
# con sus partidos) y simulate (simular todos los partidos pendientes de un grupo).
# Eso sí, sin el concern ApiPresenter este controlador no podría usar build_group
# ni compute_best_thirds — esa lógica vive en el concern para reutilizarse.
class GroupsController < ApplicationController
  # Este método carga los 12 grupos y calcula la tabla de mejores terceros.
  # Los mejores terceros son importantes porque de los 12 terceros, solo los
  # 8 con mejores estadísticas clasifican a la fase eliminatoria.
  def index
    raw_groups   = ApiClient.groups
    @groups      = raw_groups.map { |g| build_group(g) }
    @best_thirds = compute_best_thirds(raw_groups)
  rescue StandardError
    @groups      = []
    @best_thirds = []
  end

  # Este método carga el detalle de un grupo específico incluyendo sus partidos.
  # Si el grupo no existe (la API devuelve nil), redirige al índice en vez de
  # explotar con un error 500.
  def show
    api_group = ApiClient.group(params[:id])
    redirect_to groups_path and return unless api_group
    @group = build_group(api_group)
  rescue StandardError
    redirect_to groups_path
  end

  # Este método simula todos los partidos pendientes del grupo y redirige al
  # show del mismo grupo para que el usuario vea los resultados inmediatamente.
  def simulate
    ApiClient.simulate_group(params[:id])
    redirect_to group_path(params[:id]), notice: "Grupo simulado"
  rescue StandardError => e
    redirect_to group_path(params[:id]), alert: "Error al simular: #{e.message}"
  end

  private

  # Este método calcula los 12 terceros clasificados (uno por grupo) y los ordena
  # según los criterios FIFA: primero por puntos, luego por diferencia de goles,
  # luego por goles a favor. Solo los primeros 8 de esta lista clasifican.
  # Eso sí, sin filter_map los grupos sin tercer lugar causarían nils en el array.
  def compute_best_thirds(raw_groups)
    thirds = raw_groups.filter_map do |g|
      # Buscamos específicamente la posición 3 de cada grupo.
      s = g["standings"].find { |st| st["position"] == 3 }
      # Si el grupo no tiene tercer lugar todavía (por ejemplo sin partidos), lo saltamos.
      next unless s
      t  = s["team"]
      dg = t["goal_difference"].to_i
      {
        code:   team_code(t["name"]),
        name:   t["name"],
        group:  g["name"],
        pj:     t["matches_played"].to_i,
        pts:    t["points"].to_i,
        gf:     t["goals_for"].to_i,
        gc:     t["goals_against"].to_i,
        dg:     dg,
        dg_str: (dg >= 0 ? "+" : "") + dg.to_s,
        g:      t["wins"].to_i,
        e:      t["draws"].to_i,
        p:      t["losses"].to_i
      }
    end

    # Los valores negativos en sort_by invierten el orden (de mayor a menor).
    thirds.sort_by { |t| [-t[:pts], -t[:dg], -t[:gf]] }
  end
end
