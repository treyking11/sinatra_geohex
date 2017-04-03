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


post '/save_file' do
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]

  File.open(".public/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end
end


post '/run_script' do
  load '/get-GH-from-address.rb'
  #system("./script.sh") ''
  erb :show, layout: :main
end
