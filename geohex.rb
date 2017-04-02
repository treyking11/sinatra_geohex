require 'sinatra'


get '/' do
  erb :index
end


get '/about' do
  'A little about me.'
end


get '/form' do
  erb :form
end


not_found do
  status 404
  'Trey broke this...'
end
