require 'nokogiri'
require 'open-uri'
require 'mongo'

include Mongo

mongo_client = MongoClient.new("localhost", 27017)
DB = mongo_client.db "social_impact"

def get_value(cells, index)
  cell = cells[index]
  cell.text.strip
end

def parse_score(score)
  if score.to_i.to_s == score
    score.to_i
  else
    nil
  end
end


def scrape(slug, name)
  coll = DB[slug]
  coll.drop

  first_page = Nokogiri::HTML open("http://www.csrhub.com/search/data_source/reported/#{name}")
  num_companies = /.*: ([\d,]+.)*/.match(first_page.xpath("//div[@class='companies_found_header']").text)[1].gsub(",","").to_i
  num_pages = (num_companies*1.0/100).ceil.to_i

  (0...num_pages).each do |i|
    url = "http://www.csrhub.com/search/data_source/reported/#{name}/?page=#{i}"
    page = Nokogiri::HTML open(url)

    table = page.css('table').select { |t| t['class'] == 'lists' }[0]
    rows = table.css 'tr'
    rows = rows[1..rows.length]# Ignore header row

    rows.each do |row|
      cells = row.css 'td'
      data = {
        name: get_value(cells, 0),
        score: parse_score(get_value(cells, 1))
      }
      coll.insert(data)
    end
    puts "#{i+1} of #{num_pages}"
  end
end

# scrape(:carbon_disclosure, "Carbon%2BDisclosure%2BProject%2B2008")
# scrape(:un_global_compact, "UN%2BGlobal%2BCompact%2B2010")
scrape(:csr_wegreen, "WeGreen")
