require "mongo"
include Mongo
require "nokogiri"
require "open-uri"
require_relative "./cache.rb"
require_relative "./data/glassdoor/reviews.rb"
require "redis"

# CSRHUB_KEYS = %i{carbon_disclosure un_global_compact csr_wegreen}

mongo_client = MongoClient.new "localhost", 27017
DB = mongo_client.db "social_impact"

DB["most_reputable"].ensure_index({"Name" => Mongo::TEXT})
DB["best_regarded"].ensure_index({"Name" => Mongo::TEXT})
DB["wegreen"].ensure_index({"name" => Mongo::TEXT})
DB["women_board_members"].ensure_index({"title" => Mongo::TEXT})
DB["vigeo"].ensure_index({"name" => Mongo::TEXT})
DB["cdp"].ensure_index({"name" => Mongo::TEXT})
# CSRHUB_KEYS.each do |key|
  # DB[key.to_s].ensure_index({"name" => Mongo::TEXT})
# end

class String
  def to_slug
    return self.gsub(/[\u0080-\u00ff]/,"").strip.gsub(" ", "_").gsub(":", "").downcase.to_sym
  end
end

class SocialCompany
  attr_accessor :info

  def initialize(params)
    @name = params[:name]
    @info = {}

    most_reputable
    best_regarded
    wegreen
    women_board_members
    csrhub
    glassdoor
    vigeo
    cdp
  end

  def most_reputable
    @info[:most_reputable] = mongo_search("most_reputable", @name, {
      rank: "Rank",
      score: "Score"
    })
  end

  def vigeo
    vigeo_data = mongo_search("vigeo", @name, {name: "name"})
    @info[:vigeo] = {:on_list => (not vigeo_data.empty?)}
  end

  def best_regarded
    @info[:best_regarded] = mongo_search("best_regarded", @name, {
      rank: "Rank",
      score: "Score"
    })
  end

  def cdp
    @info[:cdp] = mongo_search("cdp", @name, {
      score: "score"
    })
  end
  def wegreen
    @info[:wegreen] = mongo_search("wegreen", @name, {
      score: "score"
    })
  end

  def women_board_members
    @info[:women_board_members] = mongo_search("women_board_members", @name, {
      total_board: "total_board",
      num_of_women: "num_of_women",
      percentage_of_women: "percentage_of_women",
      sector: "sector",
      state: "state",
      city: "city"
    })
  end

  def csrhub
    csrhub_data = REDIS.cache "csrhub_data_#{@name}" do
      begin
        url = "http://www.csrhub.com/CSR_and_sustainability_information/#{@name.gsub " ", ""}/"
        page = Nokogiri::HTML open(url)
        data = {}

        info = page.xpath("//div[@class='marg']")
        data[:description] = info.css("h2").first.text
        info_table = info.css('table').css('td').map(&:text).each_slice(2) do |k,v|
          data[k.to_slug] = v
        end
        data.delete :csr_web_area if data.include? :csr_web_area

        ratings = {}
        ratings_table = page.xpath("//table[@class='rating']")
        headers = ratings_table.css("thead").css("th").map(&:text).reject(&:empty?).map(&:to_slug)
        ratings_table.css("tbody").css("tr").each_with_index do |row, i|
          cells = row.css("td").map(&:text)
          if i == 0
            key = :adjusted
          elsif cells[0] == "All company average"
            key = :average
          else
            key = cells[0].to_slug
          end
          next if cells[1] == "Please register"
          vals = Hash[headers.zip(cells[1..cells.length].map(&:strip).map(&:to_i))]
          ratings[key] = vals
        end
        data[:ratings] = ratings
      rescue OpenURI::HTTPError
        data = {}
      end

      JSON.generate(data)
    end

    @info[:csrhub] = JSON.parse csrhub_data, symbolize_names: true
  end

  def glassdoor
    glassdoor_data = REDIS.cache "glassdoor_data_#{@name}" do
      JSON.generate Glassdoor.scrape(@name)
    end
    @info[:glassdoor] = JSON.parse glassdoor_data, symbolize_names: true
  end

  private
  def mongo_search(collection_name, name, field_mappings)
    results = DB.command(text: collection_name, search: name)["results"]
    return {} if results.empty?
    Hash[field_mappings.map { |key, db_key| [key, results[0]["obj"][db_key]] }]
  end
end
