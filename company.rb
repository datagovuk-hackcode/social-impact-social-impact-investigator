require_relative "./financial_company.rb"
require_relative "./social_company.rb"

class Company
  attr_accessor :info

  def initialize(params)
    @info = {}
    sc = SocialCompany.new(name: params[:name])
    @info.merge! sc.info
    @info.merge! FinancialCompany.new(name: params[:name], ticker: sc.info[:csrhub][:ticker]).info
  end

  def self.info(name)
    Company.new(name: name).info
  end
end
