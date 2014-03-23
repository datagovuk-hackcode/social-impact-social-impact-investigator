require 'open-uri'
require 'cgi'
require 'json'
require 'mongo'
require 'parallel'
require 'ruby-progressbar'
require_relative 'libs'

include Mongo
$mongo = MongoClient.new
$db = $mongo.db "social_impact"
$coll = $db.collection "companies"

if false
  $coll.drop
  categories = get_cached("http://localhost:9292/api/categories")
  categories.each do |category|
    puts "\#\#\##{category["name"]}"
    subcategories = get_cached category["subcategories"]
    subcategories.each do |subcategory|
      puts "#{category["name"]}: #{subcategory["name"]}"
      companies = get_cached subcategory["companies"]
      companies.each do |company|
        company["category"] = category["name"]
        company["subcategory"] = subcategory["name"]
        company.delete "url"
        $coll.insert company
      end
      sleep 0.1
    end
  end
end

if true
  companies = $coll.find.sort({"$natural" => -1})
  progress = ProgressBar.create(:total => companies.count, :format => '%a %B %p%% %t %c/%C')
  Parallel.each(companies, :finish => lambda { |item, i, result| progress.increment }) do |company|
    begin
      name = company["name"].gsub "/", ""
      data = get_cached "http://localhost:9292/api/companies/#{URI.escape name}"
      company.merge! data
      $coll.update({"_id" => company["_id"]}, company)
    rescue Exception
      puts "Failed on #{company["name"]}"
    end
  end
end
