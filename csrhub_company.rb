require 'open-uri/cached'
require 'json'
require 'babosa'
require 'parallel'
require 'yaml'

require_relative 'libs'
require_relative 'yahoo_company'
require_relative 'glassdoor'

require 'mongo'
include Mongo
$mongo = MongoClient.new("localhost", 27017)
$db = $mongo["social_impact"]
filehash= Digest::MD5.hexdigest(File.read("csrhub_company.rb"))
$coll = $db["csrhub_#{filehash}"]
$coll.create_index "search"

# TODO Remove
PROFILE_ID = "467"
BASE_URL = "https://www.csrhub.com/rest"

DATASOURCES = YAML.load_file 'csrhub.yml'
CONFIG = YAML.load_file 'config.yml'
API_KEY = CONFIG["CSRHUB_API_KEY"]

API_FIELDS = %w{search name website csrsite page ratings address basic_ratings special_issues financial reviews} + DATASOURCES.keys

class CSRHubCompany
  attr_accessor :data, :resp

  def initialize params
    @name = params[:name]
    results = $coll.find({search: @name})

    if results.count == 0
      @data = {search: @name}

      search

      # TODO In parallel below
      datas = Parallel.map([self.method(:get_details), self.method(:get_data_values), self.method(:get_financial_details), self.method(:get_reviews)]) do |f|
        f.call
      end
      datas.each { |data| @data.merge! data }

      $coll.insert(@data)
      puts "Saving"
    else
      puts "Retrieving"
      @data = results.first
      @data.delete "_id"
    end

    @resp = {}
    API_FIELDS.each { |f| @resp[f] = @data[f] }
  end

  # Find all companies in a certain category
  def self.in_category(category)
    category = category.gsub "&", "and"
    category = category.gsub /[^0-9a-z ]/i, ""
    category = category.split.join(" ") # Remove duplicate spaces
    category = category.gsub " ", "-"
    data = get_cached build_api_url("search/industry:#{URI.escape category}")
    data["companies"].map do |company|
      {
        name: company["name"],
        website: company["website"],
        ratings: company["ratings"],
        url: $api_root + "/api/companies/#{URI.escape company['name']}"
      }
    end
  end

  protected
  # Find company on CSRHub
  def search
    puts search_url
    data = get_cached search_url
    company = data["companies"].first
    @alias = company["alias"]

    @data.merge! company
  end

  # CSRHub API search url
  def search_url
    unless @name.nil?
      CSRHubCompany.build_api_url "search/name:#{URI.escape @name}"
    else
      raise CSRHubSearchException
    end
  end

  # CSRHub API details url
  def details_url
    CSRHubCompany.build_api_url "company/#{@alias}"
  end

  # Get CSRHub /company details endpoint
  def get_details
    puts details_url
    data = get_cached details_url
    puts "ddone"
    data
  end

  # Get data values one by one
  def get_data_values
    final_data = {}

    base = "value/company:#{@alias}"
    DATASOURCES.each do |datasource_slug, info|
      final_data[datasource_slug] = {} unless final_data.include? datasource_slug
      datasource = info["name"]
      elements = info["values"]

      elements.each do |slug, element|
        url = CSRHubCompany.build_api_url "value/company:#{@alias}:datasource:#{URI.escape datasource}:element:#{URI.escape element}"
        puts url
        data = get_cached url
        final_data[datasource_slug][slug.to_s] = data["Value"]
      end
    end
    puts "dvdone"

    final_data
  end

  def self.build_api_url endpoint
    "#{BASE_URL}/#{endpoint}/#{PROFILE_ID}/json/?key=#{API_KEY}"
  end

  # Use YahooCompany to get financial details
  def get_financial_details
    data = {}
    yc = YahooCompany.new @name
    data["financial"] = yc.data
    puts "ydone"

    data
  end

  # Use Glassdoor to get employee reviews
  def get_reviews
    {
      "reviews" => Glassdoor.scrape(@name)
    }
  end
end

class CSRHubSearchException < Exception
end
