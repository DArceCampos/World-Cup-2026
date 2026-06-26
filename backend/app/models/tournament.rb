# Tournament es el modelo más importante del sistema en términos de jerarquía.
# Su función es representar la Copa del Mundo completa y actuar como punto de
# entrada para acceder a grupos, equipos y partidos. Eso sí, sin este modelo
# no habría forma de saber en qué fase está el torneo ni quién ganó.
class Tournament < ApplicationRecord
  # Estos son los únicos estados válidos del torneo. La idea es que el status
  # avance en orden: setup → group_stage → knockout → finished. La validación
  # de abajo garantiza que nunca se guarde un estado que no exista en esta lista.
  STATUSES = %w[setup group_stage knockout finished].freeze

  # Un torneo tiene muchos grupos, muchos partidos, y equipos a través de los grupos.
  # El dependent: :destroy significa que si se borra el torneo, se borran en
  # cascada todos sus datos — grupos, partidos y equipos incluidos.
  has_many :groups, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :teams, through: :groups

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Estos tres métodos lo que hacen es preguntar en qué fase está el torneo
  # de forma legible. En lugar de comparar strings directamente en el código
  # con tournament.status == "knockout", se usa tournament.knockout? — más
  # claro y menos propenso a errores de tipeo.
  def group_stage?
    status == "group_stage"
  end

  def knockout?
    status == "knockout"
  end

  def finished?
    status == "finished"
  end

  # Este método busca el partido de la final en la base de datos.
  # El find_by retorna nil si todavía no se ha creado ese partido, lo cual
  # es normal hasta que las semifinales terminen.
  def final_match
    matches.find_by(phase: "final")
  end

  # Lo mismo pero para el partido por el tercer lugar.
  def third_place_match
    matches.find_by(phase: "3rd")
  end

  # Este número define cuántos terceros clasificados avanzan a dieciseisavos.
  # De los 12 grupos hay 12 terceros posibles, pero solo clasifican los 8 mejores.
  THIRD_PLACE_SPOTS = 8

  # Este método lo que hace es recoger el tercer clasificado de cada grupo,
  # descartar los nil (de grupos que aún no terminaron con .compact), ordenarlos
  # por el mismo criterio FIFA que se usa en la tabla de posiciones, y quedarse
  # con los 8 mejores. Sin este método no habría forma de saber cuáles terceros
  # merecen clasificar a la fase eliminatoria.
  def best_third_places
    groups.map(&:third_place_team).compact.sort_by(&:ranking_key).first(THIRD_PLACE_SPOTS)
  end

  # El campeón es el ganador de la final. El operador &. significa "llama este
  # método solo si final_match no es nil". Así, si la final todavía no existe
  # o no se ha jugado, devuelve nil en lugar de explotar con un error.
  def champion
    final_match&.played? ? final_match.winner : nil
  end

  # El subcampeón es el perdedor de la final. Mismo patrón seguro con &.
  def runner_up
    final_match&.played? ? final_match.loser : nil
  end

  # El tercer lugar es el ganador del partido por el tercer puesto.
  def third_place
    third_place_match&.played? ? third_place_match.winner : nil
  end
end
