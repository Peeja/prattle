require 'sinatra'

get '/' do
  haml :set_up_application
end
