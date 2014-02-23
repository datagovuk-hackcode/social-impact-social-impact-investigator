require "./company.rb"
require "./category.rb"
require "grape"

module SocialImpact
  class API < Grape::API
    format :json

    before do
      header "Access-Control-Allow-Origin", "*"
    end

    resource :companies do
      desc "Return info on a company."
      params do
        requires :name, type: String, desc: "Company Name"
      end
      route_param :name do
        get do
          name = params[:name]
          name.gsub! /[^a-zA-Z]/, " "
          Company.info name, params[:name].capitalize
        end
      end
    end

    resource :categories do
      desc "View a list of all categories."
      get do
        Category.all
      end

      desc "Get a list of companies for a certain category"
      route_param :name do
        get do
          Category.companies(params[:name])
        end
    end
    end
  end
end
