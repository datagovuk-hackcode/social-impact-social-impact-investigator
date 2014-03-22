require "grape"
require "rack/contrib"
require "./csrhub_company.rb"
require "./category.rb"

$api_root = "http://socialimpact.harryrickards.com/"

module SocialImpact
  class API < Grape::API
    use Rack::JSONP
    format :json

    before do
      header "Access-Control-Allow-Origin", "*"
      $api_root = "http://#{env['HTTP_HOST']}"
    end

    resource :companies do
      desc "See possible search filters."
      get '/search' do
        CSRHubCompany.search_filters
      end

      desc "See possible search operators."
      get '/search/:filter' do
        CSRHubCompany.search_operators params[:filter]
      end

      desc "Search for companies."
      get '/search/:search_filter', requirements: {search_filter: /.*/} do
        filter_string = params[:search_filter].split("/")
        filters = []
        filter_string.each_slice(3) do |filter, operator, value|
          filters << {
            filter: filter,
            operator: operator,
            value: value
          }
        end
        CSRHubCompany.search filters
      end

      desc "Return info on a company."
      params do
        requires :name, type: String, desc: "Company Name"
      end
      get '/:name', requirements: { name: /.*/ } do
        name = params[:name]
        # name.gsub! /[^a-zA-Z]/, " "
        company = CSRHubCompany.new name: name
        company.resp
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
          CSRHubCompany.in_category params[:name]
        end
      end
    end

    resource :subcategories do
      desc "Get a list of subcategories for a certain category"
      route_param :name do
        get do
          Category.subcategories_of params[:name]
        end
      end
    end
  end
end
