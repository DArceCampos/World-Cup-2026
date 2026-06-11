require "net/http"
require "json"
require "uri"

module ApiClient
  BASE_URL = "http://localhost:3000/api/v1"

  def self.tournament
    get("/tournament")["data"]
  end

  def self.tournament_advance
    patch("/tournament/advance", {})
  end

  def self.groups
    get("/groups")["data"]
  end

  def self.group(id)
    get("/groups/#{id}")["data"]
  end

  def self.teams
    get("/teams")["data"] || []
  end

  def self.update_team(id, params)
    patch("/teams/#{id}", { team: params })
  end

  def self.matches(phase: nil, status: nil)
    query_parts = []
    query_parts << "phase=#{phase}"   if phase
    query_parts << "status=#{status}" if status
    qs = query_parts.empty? ? "" : "?#{query_parts.join("&")}"
    get("/matches#{qs}")["data"]
  end

  def self.record_result(match_id, goals)
    patch("/matches/#{match_id}/result", goals)
  end

  def self.knockout_bracket
    get("/knockout/bracket")["data"]
  end

  def self.qualifiers
    get("/knockout/qualifiers")["data"]
  end

  def self.simulate_groups
    post("/simulations/groups", {})
  end

  def self.simulate_tournament
    post("/simulations/tournament", {})
  end

  def self.reset_groups
    post("/tournament/reset_groups", {})
  end

  private

  def self.get(path)
    uri  = URI("#{BASE_URL}#{path}")
    resp = Net::HTTP.get_response(uri)
    raise_if_error(resp)
    JSON.parse(resp.body)
  end

  def self.patch(path, params)
    uri      = URI("#{BASE_URL}#{path}")
    req      = Net::HTTP::Patch.new(uri, "Content-Type" => "application/json")
    req.body = params.to_json
    resp     = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    raise_if_error(resp)
    resp
  end

  def self.post(path, params)
    uri      = URI("#{BASE_URL}#{path}")
    req      = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = params.to_json
    resp     = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    raise_if_error(resp)
    resp
  end

  def self.raise_if_error(resp)
    return if resp.is_a?(Net::HTTPSuccess)
    body = JSON.parse(resp.body) rescue nil
    msg  = body.is_a?(Hash) ? body.dig("error", "message") : nil
    raise StandardError, msg || "Error HTTP #{resp.code}"
  end
end
