# require 'sinatra/activerecord'
# require './config/environments' #database configuration
require 'sinatra'


get '/' do
  erb :index, layout: :main
end


get '/show' do
  erb :show, layout: :main
end


get '/form' do
  erb :form
end


not_found do
  status 404
  'Trey broke this...'
end
