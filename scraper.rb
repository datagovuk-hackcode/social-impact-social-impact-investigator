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
