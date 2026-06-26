# TournamentResetter es el servicio que reinicia el torneo a su estado inicial.
# Su función es borrar todos los resultados y devolver el torneo a la fase de
# grupos para que se pueda volver a simular desde cero. Eso sí, sin este
# servicio el botón "Reiniciar torneo" del panel admin no haría absolutamente nada.
class TournamentResetter
  def initialize(tournament)
    @tournament = tournament
  end

  # Este método lo que hace es ejecutar el reinicio completo en cuatro pasos,
  # todos dentro de una misma transacción SQL. Si cualquier paso falla, todos
  # los cambios se revierten automáticamente y el torneo queda intacto.
  #
  # Los pasos son:
  # 1. Eliminar completamente todos los partidos de eliminatorias (no hay que
  #    resetearlos, se vuelven a crear cuando se avance de fase de nuevo).
  # 2. Resetear todos los partidos de grupos a "scheduled" con marcador en 0.
  # 3. Resetear todas las estadísticas de los 48 equipos a 0.
  # 4. Devolver el status del torneo a "group_stage".
  def reset_groups!
    ActiveRecord::Base.transaction do
      # delete_all es más eficiente que destroy_all porque ejecuta un solo
      # DELETE en la base de datos sin cargar los objetos en memoria.
      @tournament.matches.knockout.delete_all

      # update_all también ejecuta un solo UPDATE para todos los partidos,
      # mucho más eficiente que iterar y guardar uno por uno.
      @tournament.matches.group_phase.update_all(
        status:           "scheduled",
        home_goals:       0,
        away_goals:       0,
        home_extra_goals: 0,
        away_extra_goals: 0,
        home_penalties:   0,
        away_penalties:   0
      )

      # Lo mismo para las estadísticas de los 48 equipos — un solo UPDATE.
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
