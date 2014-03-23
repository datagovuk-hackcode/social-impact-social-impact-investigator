require "open-uri/cached"

INDUSTRY_GROUPS_URL = "http://www.csrhub.com/CSR_industry_ratings/"
INDUSTRY_SUBGROUPS_URL = "http://www.csrhub.com/industry_group/"


class Category
  def initialize name
    @name = name
    @slug = name.gsub("&", "and").gsub(" ", "-").gsub(",", "")
  end

  def subcategories
    page = Nokogiri::HTML open("#{INDUSTRY_SUBGROUPS_URL}/#{URI.escape @slug}")
    sc = Category.parse_results page
    sc.map do |subcategory|
      {
        name: subcategory,
        companies: $api_root + "/api/categories/#{URI.escape subcategory}"
      }
    end
  end

  def self.subcategories_of name
    c = Category.new name
    c.subcategories
  end

  def self.all
    page = Nokogiri::HTML open(INDUSTRY_GROUPS_URL)
    categories = parse_results page
    categories.map do |category|
      {
        name: category,
        companies: $api_root + "/api/categories/#{URI.escape category}",
        subcategories: $api_root + "/api/subcategories/#{URI.escape category}"
      }
    end
  end

  protected
  def self.parse_results page
    page.xpath("//td[@class='datasource active']//text()").map(&:text)
  end
end
