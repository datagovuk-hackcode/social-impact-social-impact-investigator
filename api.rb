require "./company.rb"
require "grape"

module SocialImpact
  class API < Grape::API
    format :json

    resource :companies do
      desc "Return info on a company."
      params do
        requires :name, type: String, desc: "Company Name"
      end
      route_param :name do
        get do
          name = params[:name]
          name.gsub! /[^a-zA-Z]/, " "
          Company.info name
        end
      end
    end
  end
end
