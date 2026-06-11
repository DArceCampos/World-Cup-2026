require "net/http"
require "json"
require "uri"

module ApiClient
  BASE_URL = "http://localhost:3000/api/v1"

  def self.tournament
    get("/tournament")["data"]
  end

  def self.groups
    get("/groups")["data"]
  end

  def self.group(id)
    get("/groups/#{id}")["data"]
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

  private

  def self.get(path)
    uri = URI("#{BASE_URL}#{path}")
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)
  end

  def self.patch(path, params)
    uri  = URI("#{BASE_URL}#{path}")
    req  = Net::HTTP::Patch.new(uri, "Content-Type" => "application/json")
    req.body = params.to_json
    Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
  end
end
