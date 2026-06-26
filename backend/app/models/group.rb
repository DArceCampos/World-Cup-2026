# Group representa uno de los 12 grupos del torneo (A–L), cada uno con 4 equipos.
# Su función es agrupar equipos, calcular la tabla de posiciones y saber si ya
# terminó de jugar. Eso sí, sin este modelo no habría forma de organizar los
# 48 equipos ni de calcular quiénes clasifican a eliminatorias.
class Group < ApplicationRecord
  # Esta constante define el límite de equipos por grupo. Se usa tanto aquí
  # como en la validación del modelo Team para que ambos compartan el mismo valor.
  MAX_TEAMS = 4

  belongs_to :tournament
  # Si se elimina un grupo, se eliminan en cascada sus equipos y partidos.
  has_many :teams, dependent: :destroy
  has_many :matches, dependent: :destroy

  # El nombre del grupo (A, B, ..., L) debe existir y ser único por torneo —
  # no puede haber dos grupos "A" en el mismo torneo.
  validates :name, presence: true,
                   uniqueness: { scope: :tournament_id }

  # Este método lo que hace es devolver los equipos del grupo ordenados usando
  # ranking_key, que implementa el desempate oficial FIFA. Es la tabla de
  # posiciones del grupo. Sin este método, habría que reordenar los equipos
  # en cada lugar del código donde se necesite mostrar la clasificación.
  def standings
    teams.sort_by(&:ranking_key)
  end

  # Este método verifica si el grupo ya terminó todos sus partidos. Lo hace
  # en dos pasos: primero chequea que exista al menos un partido (.any?), y
  # luego verifica que no quede ninguno pendiente. El .any? es importante porque
  # si un grupo no tuviera partidos, completed? devolvería false aunque
  # técnicamente no haya nada pendiente.
  def completed?
    matches.any? && matches.where(status: "scheduled").none?
  end

  # Devuelve los dos primeros de la tabla, que son los que clasifican
  # directamente a dieciseisavos de final.
  def qualified_teams
    standings.first(2)
  end

  # Devuelve el tercer clasificado del grupo, que es candidato a ser uno
  # de los 8 mejores terceros que también clasifican a dieciseisavos.
  def third_place_team
    standings[2]
  end
end
