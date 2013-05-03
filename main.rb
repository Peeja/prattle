require 'sinatra/base'
require 'haml'
require 'github_api'
require 'redis'

class Store
  class << self
    attr_reader :github

    def github
      @github ||= Github.new(client_id: client_id, client_secret: client_secret, oauth_token: oauth_token) if github_configured?
    end

    def configure_github(client_id, client_secret)
      @github = nil
      redis.set("client_id", client_id)
      redis.set("client_secret", client_secret)
    end

    def github_configured?
      client_id && client_secret
    end

    def authenticated?
      oauth_token
    end

    def set_token(token)
      @github = nil
      redis.set("oauth_token", token)
    end

    def logout!
      @github = nil
      redis.del(*%w{client_id client_secret oauth_token})
    end

    def track(repo)
      redis.set("tracking:#{repo}", true)
    end

    def untrack(repo)
      redis.del("tracking:#{repo}")
    end

    def tracking?(repo)
      redis.exists("tracking:#{repo}")
    end

    private

    def redis
      @redis ||= Redis.new
    end

    def client_id
      redis.get("client_id")
    end

    def client_secret
      redis.get("client_secret")
    end

    def oauth_token
      redis.get("oauth_token")
    end
  end
end

class PrattleApp < Sinatra::Base
  class UnprocessableEntity < RuntimeError; end

  set :haml, :format => :html5

  get '/' do
    case
    when !Store.github_configured?
      haml :set_up_application
    when !Store.authenticated?
      redirect Store.github.authorize_url(redirect_uri: 'http://prattle.50.138.134.87.xip.io/authenticate', scope: 'repo')
    else
      redirect '/repos'
    end
  end

  post '/set_up_application' do
    Store.configure_github(
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

  get '/logout' do
    Store.logout!
    redirect '/'
  end

  get '/repos' do
    haml :repos, locals: { repos: Store.github.repos.list.map(&:full_name) }
  end

  post '/track' do
    repo_full_name = params.fetch("repo") { raise UnprocessableEntity }

    Store.github.repos.pubsubhubbub.subscribe("https://github.com/#{repo_full_name}/events/status", 'http://prattle.50.138.134.87.xip.io/notify/status')

    Store.track(repo_full_name)
    redirect '/repos'
  end

  post '/untrack' do
    repo_full_name = params.fetch("repo") { raise UnprocessableEntity }

    Store.github.repos.pubsubhubbub.unsubscribe("https://github.com/#{repo_full_name}/events/status", 'http://prattle.50.138.134.87.xip.io/notify/status')

    Store.untrack(repo_full_name)
    redirect '/repos'
  end

  post '/notify/status' do
    puts "NOTIFIED!"
    p params
  end
end
