require 'open-uri/cached'
require 'json'
require 'babosa'
require 'parallel'
require 'cgi'
require 'yaml'

require_relative 'libs'
require_relative 'yahoo_company'
require_relative 'glassdoor'
require_relative 'mission_dump'
require_relative 'wesoc'

HASH_FILES = ["csrhub_company.rb", "csrhub.yml"]

require 'mongo'
include Mongo
$mongo = MongoClient.new("localhost", 27017)
$db = $mongo["social_impact"]
filehash= Digest::MD5.hexdigest(HASH_FILES.map { |f| File.read(f) }.join("\n"))
$coll = $db["csrhub_#{filehash}"]
$coll.create_index "search"

PROFILE_ID = "467"
BASE_URL = "https://www.csrhub.com/rest"

DATASOURCES = YAML.load_file 'csrhub.yml'
CONFIG = YAML.load_file 'config.yml'
API_KEY = CONFIG["CSRHUB_API_KEY"]

API_FIELDS = %w{search name website csrsite page ratings address basic_ratings special_issues financial reviews mission_statement mission_statement_investigator mission_statement_proof news_sources twitter} + DATASOURCES.keys

# SEARCH_FILTERS = %w{overall community employees environment governance board product} + ["community dev & philanthropy", "compensation & benefits", "diversity & labor rights", "energy & climate change", "environment policy & reporting", "human rights & supply chain", "leadership ethics", "resource management", "training health & safety", "transparency & reporting"]
SEARCH_FILTERS = %w{overall community employees environment governance}
SEARCH_OPERATORS = %w{equal greater_than less_than greater_than_or_equal less_than_or_equal}

# Methods to get data we can run in parallel after search
PARALLEL_METHODS = %w{get_details get_data_values get_financial_details get_reviews get_missiondump_data get_wesoc}

# Two levels of caching:
#   File-based open-uri store indexed by requested URL
#   Mongo-based overall store indexed by search term & md5 hash of this code

class CSRHubCompany
  attr_accessor :data, :resp

  def initialize params
    @name = params[:name]
    results = $coll.find({search: @name})

    if results.count == 0
      @data = {"search" => @name}

      search

      datas = Parallel.map(PARALLEL_METHODS.map { |m| self.method(m) }) do |f|
      # datas = PARALLEL_METHODS.map { |m| self.method(m) }.map do |f|
        f.call
      end
      datas.each { |data| @data.merge! data unless data.nil? }

      @data["name"] = @name if @data["name"].nil?

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

  # Search all companies
  def self.search(filters)
    filter_string = []
    filters.each do |filter|
      rating = filter[:filter]
      rating.gsub! "&", "and"
      rating.gsub! " ", "-"

      filter_string << "#{rating}:#{filter[:operator]}:#{filter[:value]}"
    end
    filter_string = filter_string.join ":"

    # Proxy straight through to CSRHub
    puts build_api_url("search/#{filter_string}").inspect
    results = get_cached build_api_url("search/#{filter_string}")
    results["companies"].map do |company|
      {
        name: company["name"],
        website: company["website"],
        ratings: company["ratings"],
        url: $api_root + "/api/companies/#{URI.escape company['name']}"
      }
    end
  end

  # Possible search filters
  def self.search_filters
    SEARCH_FILTERS.map do |filter|
      {
        name: filter,
        url: $api_root + "/api/companies/search/#{URI.escape filter}"
      }
    end
  end

  # Possible search operators
  def self.search_operators(filter)
    SEARCH_OPERATORS.map do |operator|
      {
        name: operator,
        base_url: $api_root +  "/api/companies/search/#{URI.escape filter}/#{URI.escape operator}/",
        example_url: $api_root +  "/api/companies/search/#{URI.escape filter}/#{URI.escape operator}/50"
      }
    end
  end

  protected
  # Find company on CSRHub
  def search
    puts search_url
    data = get_cached search_url
    company = data["companies"].first
    return {} if company.nil?
    @alias = company["alias"]

    @data.merge! company
  end

  # CSRHub API search url
  def search_url
    unless @name.nil?
      name = @name.gsub "/", ""
      CSRHubCompany.build_api_url "search/name:#{URI.escape name}"
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
    return {} if @alias.nil?
    puts details_url
    data = get_cached details_url
    puts "ddone"
    data
  end

  # Get data values one by one
  def get_data_values
    return {} if @alias.nil?
    final_data = {}

    base = "value/company:#{@alias}"
    DATASOURCES.each do |datasource_slug, info|
      final_data[datasource_slug] = {name: info["name"]} unless final_data.include? datasource_slug
      datasource = info["name"]
      elements = info["values"]

      elements.each do |slug, element|
        url = CSRHubCompany.build_api_url "value/company:#{@alias}:datasource:#{URI.escape datasource}:element:#{URI.escape element}"
        puts url
        data = get_cached url
        final_data[datasource_slug][slug.to_s] = {name: element, value: data["Value"]}
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

  # Get data from MissionDump API
  def get_missiondump_data
    md = MissionDump.new @name
    md.data
  end

  # Twitter
  def get_wesoc
    ws = WeSoc.new @name
    ws.data
  end
end

class CSRHubSearchException < Exception
end
