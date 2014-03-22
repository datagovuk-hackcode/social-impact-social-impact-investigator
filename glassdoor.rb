# Encoding: utf-8

require "nokogiri"
require "open-uri"
require "open-uri/cached"

def category_to_slug(category)
  category.gsub! "&", "and"
  category.gsub! /[^a-zA-Z ]/, " "
  category.downcase!
  category.gsub! " ", "_"
  return category.to_sym
end

class String
  def strip_all
    self.strip.gsub /[\u0080-\uffff]/, ""
  end
end


class Glassdoor
  def scrape
    term = @term.gsub " ", ""
    url = "http://www.glassdoor.com/Reviews/#{term}-reviews-SRCH_KE0,#{term.length}.htm"
    
    search_html = open(url)
    search_page = Nokogiri::HTML(search_html.read)
    links = search_page.xpath "//div[@id='SearchResult_1']/div/div[@class='companyLinks']/a"
    reviews_link = links.select { |l| l.text == "Reviews" }.first
    return {} if reviews_link.nil?
    html = open( "http://www.glassdoor.com/" + URI.encode(reviews_link.attr('href')))
    page = Nokogiri::HTML(html.read)
    page.encoding = 'utf-8'
    data = {}

    data[:rating] = page.xpath("//div[@class='ratingsSummary margTop5']//span[@class='rating']").first.text.to_f
    data[:num_reviews] = page.xpath("//div[@class='ratingsSummary margTop5']//span[@class='numReviews subtle']//span[@class='count']").first.text.gsub(",", "").to_i
    ceo_approval = page.xpath("//span[@class='gdRating']//tt").first
    data[:ceo_approval] = ceo_approval.text + "%" unless ceo_approval.nil?
    data[:recommend_to_a_friend] = page.xpath("//div[@class='recommend padBot5 margBot10 margTop15']//tt").first.text + "%"

    ratings = page.xpath("//div[@class='distro padRt15 cf']")
    labels = ratings.css("label").map(&:text).map { |x| category_to_slug(x) }
    values = ratings.css("span").map { |val| val.attr("title") }.reject(&:nil?).map(&:to_f)
    data[:ratings] = Hash[labels.zip(values)]

    reviews = page.xpath("//div[@class='reviewBody floatRt']")
    # TODO Sign in to get more reviews
    data[:reviews] = [reviews[0]].map do |review|
      datum = {}
      title = review.css("h2").text.strip_all
      paras = review.xpath("//div[@class='description']/p")
      paras.each do |para|
        key = para.attr("class")
        key = "Review" if key.nil?
        key = category_to_slug(key)
        text = para.css("tt").text.strip_all
        text = para.text.strip_all if text.empty? or text.nil?
        datum[key] = text
      end

      datum
    end

    puts "csr done"

    data
  end

  def initialize(params)
    @term = params[:term]
  end

  def self.scrape(term)
    gd = Glassdoor.new term: term
    gd.scrape
  end
end
