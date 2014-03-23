require "./api.rb"

run Rack::Cascade.new [
  Rack::File.new('static'),
  Rack::URLMap.new("/api" => SocialImpact::API.new)
]
