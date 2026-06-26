# MatchesController maneja la vista de partidos de la fase de grupos.
# Permite filtrar por grupo (A–L) y por estado (pendientes/jugados), registrar
# resultados manualmente y simular partidos individuales.
class MatchesController < ApplicationController
  # Las 12 letras de los grupos, usadas para renderizar el filtro en la vista.
  LETTERS = %w[A B C D E F G H I J K L].freeze

  # Este método carga los partidos de grupo con los filtros que el usuario haya
  # seleccionado. Primero consulta el torneo para saber en qué fase estamos
  # (@tournament_status), porque la vista lo usa para decidir si mostrar
  # o no los formularios de edición de resultado.
  def index
    @group_filter  = params[:group]
    @status_filter = params[:status]
    @groups = LETTERS

    tournament = ApiClient.tournament
    @tournament_status = tournament["status"]

    # Convertimos el filtro de la URL ("scheduled"/"played") al valor que
    # entiende la API del backend. nil significa "sin filtro".
    api_status = case @status_filter
                 when "scheduled" then "scheduled"
                 when "played"    then "played"
                 end

    # Siempre pedimos solo partidos de fase de grupo (phase: "group").
    all = ApiClient.matches(phase: "group", status: api_status)

    # Si hay un filtro de grupo activo, convertimos la letra a ID numérico
    # y filtramos localmente (más simple que un segundo endpoint).
    if @group_filter.present?
      target_id = group_id_for(@group_filter)
      all = all.select { |m| m["group_id"] == target_id } if target_id
    end

    @matches = all.map { |m| build_match(m) }
  rescue StandardError
    @matches = []
    @tournament_status = "group_stage"
  end

  # Este método recibe el formulario de resultado y lo envía al backend.
  # Incluye goles de tiempo reglamentario, prórroga y penales (aunque en
  # fase de grupos los empates se quedan como empates, sin prórroga).
  def result
    goals = params.permit(:home_goals, :away_goals, :home_extra_goals,
                          :away_extra_goals, :home_penalties, :away_penalties).to_h
    ApiClient.record_result(params[:id], goals)
    redirect_back fallback_location: matches_path, notice: "Resultado guardado"
  rescue StandardError
    redirect_back fallback_location: matches_path, alert: "Error al guardar resultado"
  end

  # Este método le pide al backend que genere un resultado aleatorio para el partido.
  # Eso sí, si el partido ya tiene resultado, MatchSimulator lo va a sobreescribir
  # con uno nuevo — la simulación no es idempotente aquí.
  def simulate
    ApiClient.simulate_match(params[:id])
    redirect_back fallback_location: matches_path, notice: "Partido simulado"
  rescue StandardError => e
    redirect_back fallback_location: matches_path, alert: "Error al simular: #{e.message}"
  end
end
