require 'sinatra/base'
require 'haml'
require 'github_api'
require 'redis'
require 'json'

class Store
  class << self
    def track(repo, token)
      redis.set("tracking:#{repo}", token)
    end

    def untrack(repo)
      redis.del("tracking:#{repo}")
    end

    def tracking?(repo)
      redis.exists("tracking:#{repo}")
    end

    def token_for_repo(repo)
      redis.get("tracking:#{repo}")
    end

    def tracked_repos
      redis.keys("tracking:*").map { |key| key.sub(/^tracking:/, '') }
    end

    private

    def redis
      @redis ||= Redis.new(url: ENV["REDISTOGO_URL"])
    end
  end
end

class PrattleApp < Sinatra::Base
  class UnprocessableEntity < RuntimeError; end

  error UnprocessableEntity do
    status 422
  end

  set :haml, :format => :html5
  enable :sessions, :logging
  configure(:development) { set :session_secret, "secret" }

  get '/' do
    case
    when !configured?
      haml :set_up_application
    when !authenticated?
      haml :login
    else
      repos_from_github = github.repos.list(auto_pagination: true).map(&:full_name)
      repos = (Store.tracked_repos + repos_from_github).uniq
      haml :repos, locals: { repos: repos }
    end
  end

  get '/authenticate' do
    code = params.fetch("code") { raise UnprocessableEntity }
    token = github.get_token(code).token
    authenticate_as!(token)
    redirect '/'
  end

  get '/login' do
    redirect github.authorize_url(redirect_uri: url('/authenticate'), scope: 'repo')
  end

  get '/logout' do
    logout!
    redirect '/'
  end

  post '/track' do
    repo_full_name = params.fetch("repo") { raise UnprocessableEntity }
    github.repos.pubsubhubbub.subscribe("https://github.com/#{repo_full_name}/events/status", url("/notify/status"))
    Store.track(repo_full_name, oauth_token)
    redirect '/'
  end

  post '/untrack' do
    repo_full_name = params.fetch("repo") { raise UnprocessableEntity }
    github.repos.pubsubhubbub.unsubscribe("https://github.com/#{repo_full_name}/events/status", url("/notify/status"))
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

      # This is a weird way to do this. We need to get the Github client to use the right token.
      authenticate_as!(Store.token_for_repo(pull_request['head']['repo']['full_name']))

      case state
      when "success"
        github.post_request(comments_url, body: "This pull request is good to merge.")
      when "failure"
        github.post_request(comments_url, body: "This pull request has failed.")
      end
    end
  end

  def github
    raise "Tried to use Github, but it's not configured!" unless configured?
    Github.new(client_id: github_client_id, client_secret: github_client_secret, oauth_token: oauth_token)
  end

  def github_client_id
    ENV["GITHUB_CLIENT_ID"]
  end

  def github_client_secret
    ENV["GITHUB_CLIENT_SECRET"]
  end

  def configured?
    github_client_id && github_client_secret
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
