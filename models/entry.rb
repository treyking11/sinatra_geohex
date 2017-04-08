require_relative "connection"

class Entry < ActiveRecord::Base



  #  Method to export lat/long and radius
  def create_csv_for_LLR(csv_data)

     csv_string = CSV.open("#{$basefile}LLR.csv", "wb") do |csv|

       csv << csv_data.first.keys
       csv_data.each do |hash|
         csv << hash.values
       end
     end
  end


  #  Method to export GeoHexes in SQL-Ready format
  def create_csv_for_GH(csv_data)

     csv_string = CSV.open("#{$basefile}GH.csv", "wb") do |csv|

       csv_data.each do |hash|
         csv << hash

       end
     end
  end









end
