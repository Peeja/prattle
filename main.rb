require 'sinatra'

set :haml, :format => :html5

client_id = nil
client_secret = nil

class UnprocessableEntity < RuntimeError; end

get '/' do
  if client_id && client_secret
    "Client ID: #{client_id}\nClient Secret: #{client_secret}"
  else
    haml :set_up_application
  end
end

post '/set_up_application' do
  client_id = params.fetch("client_id") { raise UnprocessableEntity }
  client_secret = params.fetch("client_secret") { raise UnprocessableEntity }
  redirect '/'
end
