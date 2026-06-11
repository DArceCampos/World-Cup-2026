class MatchesController < ApplicationController
  LETTERS = %w[A B C D E F G H I J K L].freeze

  def index
    @group_filter  = params[:group]
    @status_filter = params[:status]
    @groups = LETTERS

    api_status = case @status_filter
                 when "scheduled" then "scheduled"
                 when "played"    then "played"
                 end

    all = ApiClient.matches(phase: "group", status: api_status)

    if @group_filter.present?
      target_id = group_id_for(@group_filter)
      all = all.select { |m| m["group_id"] == target_id } if target_id
    end

    @matches = all.map { |m| build_match(m) }
  rescue StandardError
    @matches = []
  end

  def result
    goals = params.permit(:home_goals, :away_goals, :home_extra_goals,
                          :away_extra_goals, :home_penalties, :away_penalties).to_h
    ApiClient.record_result(params[:id], goals)
    redirect_back fallback_location: matches_path, notice: "Resultado guardado"
  rescue StandardError
    redirect_back fallback_location: matches_path, alert: "Error al guardar resultado"
  end
end
