require "net/http"
require "json"
require "uri"

# ApiClient es el módulo que encapsula todas las llamadas HTTP al backend.
# Su función es ser el único punto del frontend que sabe que existe un backend
# en localhost:3000. Eso sí, sin este módulo cada controlador del frontend
# tendría que construir las URLs, manejar la serialización JSON y los errores
# HTTP por su cuenta — habría muchísima duplicación.
#
# Al ser un módulo (no una clase), sus métodos son todos de clase (self.) y
# no se crean instancias de ApiClient en ningún lado.
module ApiClient
  BASE_URL = "http://localhost:3000/api/v1"

  # Obtiene el estado actual del torneo con campeón, subcampeón y tercero.
  def self.tournament
    get("/tournament")["data"]
  end

  # Avanza la fase del torneo (group_stage → knockout, o siguiente ronda).
  def self.tournament_advance
    patch("/tournament/advance", {})
  end

  # Obtiene los 12 grupos con sus tablas de posiciones.
  def self.groups
    get("/groups")["data"]
  end

  # Obtiene el detalle de un grupo específico incluyendo sus partidos.
  def self.group(id)
    get("/groups/#{id}")["data"]
  end

  # Obtiene todos los equipos con sus estadísticas.
  def self.teams
    get("/teams")["data"] || []
  end

  # Actualiza el nombre o código de un equipo. Envuelve los params en { team: }
  # porque el backend usa strong parameters con params.require(:team).
  def self.update_team(id, params)
    patch("/teams/#{id}", { team: params })
  end

  # Restaura todos los equipos a sus nombres y códigos FIFA originales.
  def self.reset_teams
    post("/teams/reset_names", {})
  end

  # Obtiene partidos con filtros opcionales por fase y estado.
  # Los parámetros se convierten en query string: ?phase=group&status=scheduled
  def self.matches(phase: nil, status: nil)
    query_parts = []
    query_parts << "phase=#{phase}"   if phase
    query_parts << "status=#{status}" if status
    qs = query_parts.empty? ? "" : "?#{query_parts.join("&")}"
    get("/matches#{qs}")["data"]
  end

  # Registra el resultado de un partido enviando los goles al backend.
  def self.record_result(match_id, goals)
    patch("/matches/#{match_id}/result", goals)
  end

  # Obtiene el bracket completo de la fase eliminatoria agrupado por ronda.
  def self.knockout_bracket
    get("/knockout/bracket")["data"]
  end

  # Obtiene los 32 clasificados a dieciseisavos (24 directos + 8 mejores terceros).
  def self.qualifiers
    get("/knockout/qualifiers")["data"]
  end

  # Simula un partido específico generando un resultado aleatorio.
  def self.simulate_match(match_id)
    post("/simulations/match/#{match_id}", {})
  end

  # Simula todos los partidos pendientes de un grupo específico.
  def self.simulate_group(group_id)
    post("/simulations/group/#{group_id}", {})
  end

  # Simula todos los partidos pendientes de la fase de grupos completa.
  def self.simulate_groups
    post("/simulations/groups", {})
  end

  # Simula el torneo completo desde donde esté hasta que haya campeón.
  def self.simulate_tournament
    post("/simulations/tournament", {})
  end

  # Reinicia todos los resultados del torneo volviendo a la fase de grupos.
  def self.reset_groups
    post("/tournament/reset_groups", {})
  end

  private

  # Este método hace un GET al backend y parsea la respuesta JSON.
  # Si la respuesta no es exitosa, raise_if_error lanza una excepción
  # que los controladores capturan con rescue StandardError.
  def self.get(path)
    uri  = URI("#{BASE_URL}#{path}")
    resp = Net::HTTP.get_response(uri)
    raise_if_error(resp)
    JSON.parse(resp.body)
  end

  # Este método hace un PATCH al backend con body JSON.
  def self.patch(path, params)
    uri      = URI("#{BASE_URL}#{path}")
    req      = Net::HTTP::Patch.new(uri, "Content-Type" => "application/json")
    req.body = params.to_json
    resp     = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    raise_if_error(resp)
    resp
  end

  # Este método hace un POST al backend con body JSON.
  def self.post(path, params)
    uri      = URI("#{BASE_URL}#{path}")
    req      = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = params.to_json
    resp     = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    raise_if_error(resp)
    resp
  end

  # Este método verifica si la respuesta fue exitosa (2xx). Si no lo fue,
  # intenta parsear el mensaje de error del JSON del backend y lo lanza como
  # StandardError. Eso sí, sin este método todos los errores del backend
  # pasarían desapercibidos y el frontend mostraría datos vacíos sin avisar.
  def self.raise_if_error(resp)
    return if resp.is_a?(Net::HTTPSuccess)
    body = JSON.parse(resp.body) rescue nil
    err  = body.is_a?(Hash) ? body["error"] : nil
    msg  = err.is_a?(Hash) ? err["message"] : err
    raise StandardError, msg || "Error HTTP #{resp.code}"
  end
end
