require_relative 'libs'

WESOC_URL = "http://wesoc.herokuapp.com/companies"

class WeSoc
  def initialize name
    @name = name
  end

  def data
    name = @name.gsub "/", ""
    name = @name.gsub ".", " "
    puts "#{WESOC_URL}/#{URI.escape name}"
    get_cached "#{WESOC_URL}/#{URI.escape name}"
  end
end
