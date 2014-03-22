require "grape"
require "rack/contrib"
require "./csrhub_company.rb"
require "./category.rb"

$api_root = "http://socialimpact.harryrickards.com/"

module SocialImpact
  class API < Grape::API
    use Rack::JSONP
    format :json

    helpers do
      # TODO Is there not a gem that can do this in a less hackish, less likely
      # to break way?
      def format_output data
        if data.is_a? Hash
          return Hash[data.map { |k, v| [k, format_output(v)] }]
        elsif data.is_a? Array
          return data.map { |x| format_output(x) }
        elsif data.is_a? String
          datai = data.to_i
          dataf = data.to_f
          if (%w{N/A NA - NR} << "").include? data
            return nil
          elsif datai.to_s == data
            return datai
          elsif (Float(data) rescue false)
            return dataf
          # elsif data =~ /(N\/A|[\d+\-%]*) +- +(N\/A|[\d+\-%\.]*)/i
            # groups = data.match /(N\/A|[\d+\-%]*) +- +(N\/A|[\d+\-%\.]*)/i
            # return format_output [groups[1], groups[2]]
          elsif data[0] == "+"
            num = format_output(data[1..-1])
            if num.is_a? String
              return data
            else
              return num
            end
          elsif data[0] == "-"
            num = format_output(data[1..-1])
            unless num.is_a? Integer or num.is_a? Float
              return data
            else
              return -num
            end
          else
            data.gsub! /<b>(.*)<\/b>/i, '\1'
            data.gsub! "&nbsp;", ""
            return data
          end
        else
          return data
        end
      end
    end
    before do
      header "Access-Control-Allow-Origin", "*"
      $api_root = "http://#{env['HTTP_HOST']}"
    end

    resource :companies do
      desc "See possible search filters."
      get '/search' do
        format_output CSRHubCompany.search_filters
      end

      desc "See possible search operators."
      get '/search/:filter' do
        format_output CSRHubCompany.search_operators(params[:filter])
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
        format_output CSRHubCompany.search(filters)
      end

      desc "Return info on a company."
      params do
        requires :name, type: String, desc: "Company Name"
      end
      get '/:name', requirements: { name: /.*/ } do
        name = params[:name]
        name = name[0...-1] if name[-1] == "."
        # name.gsub! /[^a-zA-Z]/, " "
        company = CSRHubCompany.new name: name
        format_output company.resp
      end
    end

    resource :categories do
      desc "View a list of all categories."
      get do
        format_output Category.all
      end

      desc "Get a list of companies for a certain category"
      route_param :name do
        get do
          format_output CSRHubCompany.in_category(params[:name])
        end
      end
    end

    resource :subcategories do
      desc "Get a list of subcategories for a certain category"
      route_param :name do
        get do
          format_output Category.subcategories_of(params[:name])
        end
      end
    end
  end
end
