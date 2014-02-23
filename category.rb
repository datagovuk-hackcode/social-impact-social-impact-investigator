require "mongo"
include Mongo

COLL = DB["women_board_members"]

class Category
  def initialize(params)
    @name = params[:name].split.map { |w| w.capitalize }.join(" ")
  end

  def self.all
    COLL.find({}, {fields:["sector"]}).map { |r| r["sector"] }.uniq.reject(&:nil?).reject(&:empty?)
  end

  def self.companies(name)
    category = Category.new name: name
    category.companies
  end

  def companies
    names = COLL.find({"sector"=>@name}).map { |r| r["title"] }.uniq.reject(&:nil?).reject(&:empty?)
    names.map do |name|
      name.gsub! /,? Inc\.?$/, ""
      {
        name: name,
        url: "/api/companies/#{URI.escape name.gsub(/[^a-zA-Z ]/, "")}"
      }
    end
  end
end
