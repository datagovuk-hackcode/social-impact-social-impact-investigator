require 'open-uri/cached'
require 'nokogiri'
require 'sanitize'
require 'json'

DETAILS_URL = "http://query.yahooapis.com/v1/public/yql"

class YahooCompany
  attr_accessor :data

  def initialize name
    @name = name
    @data = {}

    get_ticker
    get_stocks unless @ticker.nil?
    @data[:chart] = "http://chart.finance.yahoo.com/z?s=#{@ticker}&t=5y&q=&l=&z=l&a=v&p=s&lang=en-US&region=US"
  end

  protected
  def get_ticker
    url = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=#{URI.escape @name}&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
    jsonp = open(url).read
    data = JSON.parse jsonp[/{.+}/]
    result = data["ResultSet"]["Result"]
    @ticker = result.first["symbol"] unless result.nil? or result.empty?
  end

  def get_stocks
    query = "select * from yahoo.finance.quotes where symbol in ('#{@ticker}')"
    url = "#{DETAILS_URL}?q=#{URI.encode query}&format=json&env=http://datatables.org/alltables.env"
    data = get_cached url
    @data = data["query"]["results"]["quote"] unless data["query"]["results"].nil? or data["query"]["results"].empty?
  end
end
