require 'sinatra/base'
require 'haml'
require 'github_api'
require 'redis'
require 'json'

class Store
  class << self
    attr_reader :github

    def github
      @github ||= Github.new(client_id: client_id, client_secret: client_secret, oauth_token: oauth_token) if github_configured?
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
      redis.del(*%w{oauth_token})
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
      ENV["GITHUB_CLIENT_ID"]
    end

    def client_secret
      ENV["GITHUB_CLIENT_SECRET"]
    end

    def oauth_token
      redis.get("oauth_token")
    end
  end
end

class PrattleApp < Sinatra::Base
  class UnprocessableEntity < RuntimeError; end

  error UnprocessableEntity do
    status 422
  end

  set :haml, :format => :html5

  get '/' do
    case
    when !Store.github_configured?
      haml :set_up_application
    when !Store.authenticated?
      haml :login
    else
      redirect '/repos'
    end
  end

  get '/authenticate' do
    code = params.fetch("code") { raise UnprocessableEntity }
    token = Store.github.get_token(code).token
    Store.set_token(token)
    redirect '/repos'
  end

  get '/login' do
    redirect Store.github.authorize_url(redirect_uri: 'http://prattle.50.138.134.87.xip.io/authenticate', scope: 'repo')
  end

  get '/logout' do
    Store.logout!
    redirect '/'
  end

  get '/repos' do
    haml :repos, locals: { repos: Store.github.repos.list(auto_pagination: true).map(&:full_name) }
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
    payload = JSON.parse(params['payload'])

    sha = payload['sha']
    state = payload['state']
    pull_request = payload['pull_request']

    if pull_request
      comments_url = pull_request['comments_url']

      case state
      when "success"
        Store.github.post_request(comments_url, body: "This pull request is good to merge.")
      when "failure"
        Store.github.post_request(comments_url, body: "This pull request has failed.")
      end
    end
  end
end
