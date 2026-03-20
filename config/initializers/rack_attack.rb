class Rack::Attack
  # Throttle API requests by API key
  throttle("api/key", limit: 300, period: 5.minutes) do |req|
    if req.path.start_with?("/api/")
      req.env["HTTP_AUTHORIZATION"]&.sub(/^Bearer\s+/, "")
    end
  end

  # Throttle API requests by IP (fallback)
  throttle("api/ip", limit: 100, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Block suspicious requests
  blocklist("fail2ban/api") do |req|
    Rack::Attack::Fail2Ban.filter("api-auth-#{req.ip}", maxretry: 20, findtime: 1.minute, bantime: 30.minutes) do
      req.path.start_with?("/api/") && req.env["rack.attack.matched"] == "api/key"
    end
  end

  self.throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ error: "Rate limit exceeded. Retry after #{retry_after} seconds." }.to_json]
    ]
  end
end
