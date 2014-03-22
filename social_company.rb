require "mongo"
include Mongo
require "nokogiri"
require "open-uri"
require_relative "./cache.rb"
require_relative "./libs.rb"
require_relative "./data/glassdoor/reviews.rb"
require "redis"
require "mongo"
include Mongo

# TODO Set these values, or ideally let the user set them
SOCIAL_OFFSETS = {
  most_reputable: 0,
  best_regarded: 0,
  wegreen:  3.5,
  women_board_members: 50,
  csrhub_overall: 30,
  csrhub_community: 50,
  csrhub_employees: 50,
  csrhub_environment: 50,
  csrhub_governance: 50,
  glassdoor_rating: 3.0,
  ceo_approval: 70,
  recommend_to_a_friend: 80,
  glassdoor_culture_and_values: 3.0,
  glassdoor_work_life_balance: 3.0,
  glassdoor_senior_management: 3.0,
  glassdoor_comp_and_benefits: 3.0,
  glassdoor_career_opportunities: 3.0,
  vigeo: 0.2
}
SOCIAL_WEIGHTS = {
  most_reputable: 0,
  best_regarded: 0,
  wegreen:  5,
  women_board_members: 0,
  csrhub_overall: 1,
  csrhub_community: 0,
  csrhub_employees: 0,
  csrhub_environment: 0,
  csrhub_governance: 0,
  glassdoor_rating: 5,
  ceo_approval: 0,
  recommend_to_a_friend: 0,
  glassdoor_culture_and_values: 0,
  glassdoor_work_life_balance: 0,
  glassdoor_senior_management: 0,
  glassdoor_comp_and_benefits: 0,
  glassdoor_career_opportunities: 0,
  vigeo: 0
}

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

def strip_percentage(str)
  str[0...str.length-1].to_f
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
    overall_score
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
        search_url = "http://www.csrhub.com/search/name/#{@name.gsub " ", ""}/"
        search_results = Nokogiri::HTML open(search_url)
        company_link = "http://www.csrhub.com/" + search_results.xpath("//td[@class='company_name']/a").attr("href")

        page = Nokogiri::HTML open(company_link)
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

  def overall_score
    scores = []

    %i{most_reputable best_regarded}.each do |key|
      scores << (@info[key][:score]-SOCIAL_OFFSETS[key])*SOCIAL_WEIGHTS[key] unless @info[key].empty?
    end

    scores << (5-@info[:wegreen][:score].to_f-SOCIAL_OFFSETS[:wegreen])*SOCIAL_WEIGHTS[:wegreen] unless @info[:wegreen].empty?

    unless @info[:women_board_members].empty?
      percentage = strip_percentage(@info[:women_board_members][:percentage_of_women])
      scores << (percentage-SOCIAL_OFFSETS[:women_board_members])*SOCIAL_WEIGHTS[:women_board_members]
    end

    unless @info[:csrhub].empty?
      ratings = @info[:csrhub][:ratings][:average]
      ratings.each do |key, rating|
        key = "csrhub_#{key}"
        scores << (rating-SOCIAL_OFFSETS[key.to_sym])*SOCIAL_WEIGHTS[key.to_sym]
      end
    end

    unless @info[:glassdoor].empty?
      gd = @info[:glassdoor]
      scores << (gd[:rating]-SOCIAL_OFFSETS[:glassdoor_rating])*SOCIAL_WEIGHTS[:glassdoor_rating]
      scores << (strip_percentage(gd[:ceo_approval])-SOCIAL_OFFSETS[:ceo_approval])*SOCIAL_WEIGHTS[:ceo_approval]
      scores << (strip_percentage(gd[:recommend_to_a_friend])-SOCIAL_OFFSETS[:recommend_to_a_friend])*SOCIAL_WEIGHTS[:recommend_to_a_friend]

      ratings = gd[:ratings]
      ratings.each do |key, rating|
        key = "glassdoor_#{key}"
        scores << (rating-SOCIAL_OFFSETS[key.to_sym])*SOCIAL_WEIGHTS[key.to_sym]
      end
    end

    scores << ((@info[:vigeo][:on_list] ? 1 : 0)-SOCIAL_OFFSETS[:vigeo])*SOCIAL_WEIGHTS[:vigeo] unless @info[:vigeo].empty?

    scores.reject!(&:nil?)
    scores.reject!(&:zero?)
    score = scores.reduce(:+)/scores.length*10
    @info[:social_impact_score] = score.signif(2)
  end

  private
  def mongo_search(collection_name, name, field_mappings)
    results = DB.command(text: collection_name, search: name)["results"]
    return {} if results.empty?
    Hash[field_mappings.map { |key, db_key| [key, results[0]["obj"][db_key]] }]
  end
end
