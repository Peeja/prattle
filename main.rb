require 'sinatra/base'
require 'haml'
require 'github_api'

class Store
  class << self
    attr_reader :github

    def set_github_app_info(client_id, client_secret)
      @github = Github.new(:client_id => client_id, :client_secret => client_secret)
    end

    def github_configured?
      !@github.nil?
    end

    def set_token(token)
      @github.oauth_token = token
    end
  end
end

class PrattleApp < Sinatra::Base
  class UnprocessableEntity < RuntimeError; end

  set :haml, :format => :html5

  get '/' do
    if Store.github_configured?
      redirect Store.github.authorize_url(redirect_uri: 'http://prattle.dev/authenticate')
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

  get '/authenticate' do
    code = params.fetch("code") { raise UnprocessableEntity }
    token = Store.github.get_token(code).token
    Store.set_token(token)
    redirect '/repos'
  end

  get '/repos' do
    Store.github.repos.list.inspect
  end
end
