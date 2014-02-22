require "csv"
require "mongo"

include Mongo

mongo_client = MongoClient.new("localhost", 27017)
db = mongo_client.db "social_impact"
coll = db["wegreen"]
coll.drop

Dir["./*.csv"].each do |filename|
  puts filename
  CSV.foreach(filename, "r:ISO-8859-1") do |row|
    next unless row.first.to_i.to_s == row.first and not row.first.empty?
    name = row[1]
    name = name.encode('UTF-8', :invalid => :replace, :undef => :replace)
    data = {
      name: name,
      score: row[3]
    }
    coll.insert data
  end
end
