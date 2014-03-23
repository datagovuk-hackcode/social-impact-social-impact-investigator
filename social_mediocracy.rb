require_relative 'libs'

class SocialMediocracy
  BASE_URL = "http://msom.eu01.aws.af.cm/index.php/companies"

  def initialize(name)
    @name = name.gsub(".", " ").gsub("/", "")
  end

  def data
    puts "#{BASE_URL}/#{URI.escape @name}".inspect
    d = get_cached "#{BASE_URL}/#{URI.escape @name}"
    d.delete "_id" if d.include? "_id"

    d
  end
end
