# require 'sinatra/activerecord'
# require './config/environments' #database configuration
require 'sinatra'
require 'CSV'
require 'tempfile'


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

post '/upload' do
  $filename = params[:filename]
  content = CSV.read($filename).to_s

  return content

end


# post "/upload" do
#   File.open(params[:file][:filename], "w") do |f|
#     f.write(params[:file][:tempfile].read)
#   end
#   return "success"
# end



post '/run_script' do
  load '/get-GH-from-address.rb'
  #system("./script.sh") ''
  erb :show, layout: :main
end
