require_relative 'libs'

MD_BASE_URL = "http://mdump.herokuapp.com/"
class MissionDump
  def initialize name
    @name = name
  end

  def data
    get_cached(search_url).first
  end

  protected
  def search_url
    "#{MD_BASE_URL}/search/#{URI.escape @name}.json"
  end
end
