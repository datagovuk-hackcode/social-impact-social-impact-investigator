require 'nokogiri'
require 'mongo'
require 'open-uri'

include Mongo

mongo_client = MongoClient.new("localhost", 27017)
db = mongo_client.db "social_impact"
coll = db["women_board_members"]
coll.drop

def get_value(cells, index)
  cell = cells[index]
  cell.text.strip
end

(0..31).each do |i|
  url = "http://www.2020wob.com/company-directory?page=#{i}&company=&city=&women_on_board=&sector=All&state=All&rating="
  page = Nokogiri::HTML open(url)
  rows = page.css 'tr'
  rows = rows[1..rows.length]

  rows.each do |row|
    cells = row.css 'td'
    data = {
      title: get_value(cells, 0),
      total_board: get_value(cells, 2).to_i,
      num_of_women: get_value(cells, 3).to_i,
      percentage_of_women: get_value(cells, 4),
      sector: get_value(cells, 5),
      state: get_value(cells, 6),
      city: get_value(cells, 7)
    }
    coll.insert(data)
  end

  puts "#{i} of 31"
end
