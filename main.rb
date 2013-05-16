require 'sinatra/base'
require 'haml'
require 'github_api'
require 'redis'
require 'json'

class Store
  class << self
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
  end
end

class PrattleApp < Sinatra::Base
  class UnprocessableEntity < RuntimeError; end

  error UnprocessableEntity do
    status 422
  end

  set :haml, :format => :html5
  enable :sessions
  configure(:development) { set :session_secret, "secret" }

  get '/' do
    case
    when !github_configured?
      haml :set_up_application
    when !authenticated?
      haml :login
    else
      haml :repos, locals: { repos: github.repos.list(auto_pagination: true).map(&:full_name) }
    end
  end

  get '/authenticate' do
    code = params.fetch("code") { raise UnprocessableEntity }
    token = github.get_token(code).token
    authenticate_as!(token)
    redirect '/'
  end

  get '/login' do
    redirect github.authorize_url(redirect_uri: 'http://prattle.50.138.134.87.xip.io/authenticate', scope: 'repo')
  end

  get '/logout' do
    logout!
    redirect '/'
  end

  post '/track' do
    repo_full_name = params.fetch("repo") { raise UnprocessableEntity }

    github.repos.pubsubhubbub.subscribe("https://github.com/#{repo_full_name}/events/status", 'http://prattle.50.138.134.87.xip.io/notify/status')

    Store.track(repo_full_name)
    redirect '/'
  end

  post '/untrack' do
    repo_full_name = params.fetch("repo") { raise UnprocessableEntity }

    github.repos.pubsubhubbub.unsubscribe("https://github.com/#{repo_full_name}/events/status", 'http://prattle.50.138.134.87.xip.io/notify/status')

    Store.untrack(repo_full_name)
    redirect '/'
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
        github.post_request(comments_url, body: "This pull request is good to merge.")
      when "failure"
        github.post_request(comments_url, body: "This pull request has failed.")
      end
    end
  end

  def github
    raise "Tried to use Github, but it's not configured!" unless github_configured?
    Github.new(client_id: client_id, client_secret: client_secret, oauth_token: oauth_token)
  end

  def client_id
    ENV["GITHUB_CLIENT_ID"]
  end

  def client_secret
    ENV["GITHUB_CLIENT_SECRET"]
  end

  def github_configured?
    client_id && client_secret
  end

  def authenticated?
    oauth_token
  end

  def logout!
    session["oauth_token"] = nil
  end

  def authenticate_as!(token)
    session["oauth_token"] = token
  end

  def oauth_token
    session["oauth_token"]
  end

end
