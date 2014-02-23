require "rubygems"
require "httparty"
require "redis"
require_relative "./cache.rb"
require_relative "./libs.rb"
require "yahoo_finance"
require "net/http"
require "uri"
require "digest/md5"
require "json"

DUEDIL_KEY = "ct78nurp9tbeb7b9zxqmr627"
BASE_DUEDIL_API = "api.duedil.com/sandbox/v2/"

STOCK_FIELDS = %i{average_daily_volume bid dividend_per_share earnings_per_share low_52_weeks high_52_weeks close symbol dividend_yield stock_exchange market_capitalization}
STOCK_FIELDS_HASH = Digest::MD5.hexdigest(STOCK_FIELDS.join)
STOCK_NUM_DAYS = 365
STOCK_PERIOD = :monthly

FINANCIAL_OFFSETS = {
  dividend: 0,
  close: 200
}
FINANCIAL_WEIGHTS = {
  dividend: 1,
  close: 0.05
}


REDIS = Redis.new(
  thread_safe: true,
  db: 'social_impact'
)

class String
  def rchomp(sep = $/)
    self.start_with?(sep) ? self[sep.size..-1] : self
  end
end

class Duedil
  include HTTParty
  base_uri BASE_DUEDIL_API

  def get(endpoint, params)
    resp = self.class.get(endpoint, {query:params.merge(api_key: DUEDIL_KEY)})
    puts resp.request.last_uri.to_s
    return resp
  end
end

class FinancialCompany
  attr_accessor :info

  def initialize(params)
    @name = params[:name]
    @info = {}
    @duedil = Duedil.new

    get_duedil_id
    get_duedil

    # get_stock_symbol
    @ticker = params[:ticker]
    if @ticker.nil? or @ticker == "nil" or @ticker.empty?
      @info[:stocks] = {}
    else
      get_yahoo
      stocks_chart
    end

    overall_score
  end

  def get_duedil_id
    # TODO Really hackish
    return @duedil_id = "01591116" if @name.downcase == "apple"

    @duedil_id = REDIS.cache "duedil_id_v1_#{@name}" do
      endpoint = "/search/companies"
      params = {
        query: @name
      }
      response = @duedil.get(endpoint, params)
      begin
        id = response["response"]["data"][0]["id"]
      rescue NoMethodError
        id = nil
      end
      id
    end
  end

  def get_duedil
    financial = REDIS.cache "duedil_info_v2_#{@duedil_id}" do
      endpoint = "/company/#{@duedil_id}"
      params = {
        fields: 'get_all'
      }
      response = @duedil.get(endpoint, params)
      if response.code == 404
        response = {}
      else
        response = response["response"]
      end
      JSON.generate response
    end
    @info[:financial] = JSON.parse financial
  end

  # def get_stock_symbol
    # @stock_symbol = REDIS.cache "stock_symbol_v1_#{@name}" do
      # url = URI.parse "http://finance.yahoo.com/q?s=#{URI.escape @name}"
      # req = Net::HTTP.get(url)
      # match = /.*yahoo.com\/q\?s=([a-zA-Z]+)">/.match(req)
      # if match.nil?
        # "nil"
      # else
        # match[1]
      # end
    # end
  # end
  
  def get_yahoo
    stocks = REDIS.cache "stock_yahoo_v7_#{STOCK_FIELDS_HASH}_#{@ticker}_#{STOCK_NUM_DAYS}_#{STOCK_PERIOD}" do
      data = YahooFinance.quotes(
        [@ticker],
        STOCK_FIELDS,
        raw: false
      )[0].marshal_dump
      data[:symbol] = data[:symbol].rchomp('"').chomp('"') unless data[:symbol].nil?
      data[:stock_exchange] = data[:stock_exchange].rchomp('"').chomp('"') unless data[:symbol].nil?

      # TODO yahoo-finance historical data not working
      # data[:historical] = YahooFinance.historical_quotes(
      #   @ticket,
      #   Time::now-24*60*60*STOCK_NUM_DAYS,
      #   Time::now,
      #   {
      #     raw: false,
      #     period: STOCK_PERIOD
      #   }
      # )

      JSON.generate(data)
    end
    @info[:stocks] = JSON.parse stocks, symbolize_names: true
  end

  def overall_score
    if @info[:stocks].empty?
      @info[:financial_score] = 0
    else
      scores = []
      scores << (@info[:stocks][:dividend_per_share]-FINANCIAL_OFFSETS[:dividend])*FINANCIAL_WEIGHTS[:dividend] unless @info[:stocks][:dividend_per_share].zero?
      scores << (@info[:stocks][:close]-FINANCIAL_OFFSETS[:close])*FINANCIAL_WEIGHTS[:close] unless @info[:stocks][:close].zero?
      if scores.empty?
        @info[:financial_score] = 0
      else
        score = scores.reduce(:+)/scores.length
        @info[:financial_score] = score.signif(2)
      end
    end
  end

  def stocks_chart
    @info[:stocks][:stocks_chart] = "http://chart.finance.yahoo.com/z?s=#{@ticker}&t=5y&q=&l=&z=l&a=v&p=s&lang=en-US&region=US"
  end
end
