require "./api.rb"

run Rack::URLMap.new "/api" => SocialImpact::API.new
