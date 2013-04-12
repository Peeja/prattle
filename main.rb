require 'sinatra/base'

class Store
  class << self
    attr_reader :client_id, :client_secret

    def set_github_app_info(client_id, client_secret)
      @client_id = client_id
      @client_secret = client_secret
    end

    def has_github_app_info?
      @client_id && @client_secret
    end
  end
end

class PrattleApp < Sinatra::Base
  class UnprocessableEntity < RuntimeError; end

  set :haml, :format => :html5

  get '/' do
    if Store.has_github_app_info?
      "Client ID: #{Store.client_id}\nClient Secret: #{Store.client_secret}"
    else
      haml :set_up_application
    end
  end

  post '/set_up_application' do
    Store.set_github_app_info(
      params.fetch("client_id") { raise UnprocessableEntity },
      params.fetch("client_secret") { raise UnprocessableEntity }
    )

    redirect '/'
  end
end
