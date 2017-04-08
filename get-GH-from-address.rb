#!/usr/bin/env ruby

require 'base64'
require 'csv'
require 'pry'
require 'geocoder'
require 'json'
require 'geo_hex'

Geocoder.configure(:timeout => 10)

#  Method to return Latitude and Longitude of the addresses from the input file
def geocode_merchant(row)

  address_1           = nil
  address_2           = nil
  city                = nil
  state               = nil
  postal_code_name    = nil
  postal_code_suffix  = nil
  country             = nil
  $latitude            = nil
  $longitude           = nil
  $radius              = nil

 row.each_key do |key|

    if /Address/i.match key
      address_1 = row[key]
    elsif /Suite/i.match key
      address_2 = row[key]
    elsif /City/i.match key
      city = row[key]
    elsif /State/i.match key
      state = row[key]
    elsif /ZIP/i.match key
      postal_code_name = row[key]
    elsif /Postal Code/i.match key
      postal_code_suffix = row[key]
    elsif /Radius/i.match key
      $radius = row[key]
      
      #Checks to see if radius field is customized, defaults to radius of 5
      if $radius == nil;
        $radius = 1
        puts "#{address_1}, #{city}, #{state}, #{postal_code_name}, US"
        puts "   w/ Default Radius"
        puts ""
      else
        puts "#{address_1}, #{city}, #{state}, #{postal_code_name}, US"
        puts "   w/ Custom Radius  = #{$radius}"
        puts ""
      end

     #create address string from keys
    address_string = "#{address_1}, #{city}, #{state}, #{postal_code_name}, US"
    sleep 1
      geo_res = Geocoder.search(address_string)[0] 
  
      
      #find lat longs from string
      if geo_res
      	$latitude = geo_res.latitude 
      	$longitude = geo_res.longitude
        
        return csv_row = {
            address_1: address_1 ,
            address_2: address_2 ,
            postal_code_name: postal_code_name, 
            postal_code_suffix: postal_code_suffix,
            latitude: $latitude,
            longitude: $longitude, 
            radius: $radius,
            country_code: "US"
        }
        puts csv_row
      else
        puts "broken, redo this one"
        puts ""
      	next
      end
    end
  end
end

#  Method to unicode file
def unicode(filename, unicode_filename)
  s = IO.read(filename)
  s.encode!("UTF-16", "UTF-8", :invalid => :replace, :replace => '')
  s.encode!("UTF-8", "UTF-16")
  IO.write(unicode_filename, s)
end

#  Method to export lat/long and radius
def create_csv_for_LLR(csv_data)
   
         csv_string = CSV.open("#{$basefile}LLR.csv", "wb") do |csv|

           csv << csv_data.first.keys
           csv_data.each do |hash|
             csv << hash.values
           end
         end
end

#  Method to convert lat/long and radius to GeoHex codes
class GeoHex::Coverage < GeoHex::LL
  METERS_RANGE = (80..1_000_000).freeze
  MAX_LEVEL    = 9
  PRECISION    = 3
  ACCURACY     = 0.9

  def initialize(lat, lon)
    super(lat.to_f, lon.to_f)
  end

  # @param [Integer] meters radius in meters
  # @param [Integer] precision precision factor
  # @return [GeoHex::Zone] the best suited centroid zone
  def centroid(meters, precision = PRECISION)
    return nil unless METERS_RANGE.include?(meters)

    threshold = meters.fdiv(precision + 1)
    MAX_LEVEL.downto(0) do |level|
      zone   = ::GeoHex.encode(lat, lon, level)
      height = zone.polygon.north.to_ll.distance_to(zone.polygon.south.to_ll)
      return zone if height > threshold
    end && nil
  rescue Math::DomainError
    nil
  end

  # @param [Integer] meters radius in meters
  # @param [Hash] opts optios
  # @option [Integer] opts :precision precision factor
  # @option [Integer] opts :accuracy accuracy factor
  # @return [Array<GeoHex::Zone>] zones within `meters` at `precision`
  def within(meters, opts = {})
    precision = opts[:precision] || PRECISION
    accuracy  = opts[:accuracy] || ACCURACY
    centre    = centroid(meters, precision)
    return [] unless centre

    centre.neighbours(precision).reject do |zone|
      zone.point.to_ll.distance_to(self) * accuracy > meters
    end << centre
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

#######################################################
#  Begin Script
#######################################################

# $filename = ARGV[0]

$basefile = File.basename($filename,File.extname($filename))

# puts ""
# puts "Initializing Address to LLR to GH process for #{$filename}"
# puts ""
# puts "..."
# puts ""

# #Reads Filename (given in command)
# @csv_input_data = CSV.read($filename)
# @csv_input_headers = @csv_input_data.shift.map { |i| i.to_s }

# Creates array for returned values
csv_data = []
  #
  # puts ""
  # puts "Input addresses and radii for #{$basefile}:"
  # puts "--------------------------------------------------------------"

# Ingests input data and outputs address + lat/long + radius to csv_data array
csv_input_data.each do |row|
  row_as_hash = Hash[*csv_input_headers.zip(row).flatten]
  csv_row_with_ll = geocode_merchant(row_as_hash)
  csv_data.push(csv_row_with_ll)
end

# Exports the csv_data array to a new csv file using account name
create_csv_for_LLR(csv_data)

# Creates array for GeoHexes
gh_array = []

# Converts Lat/Long/Radius to GeoHexes
puts "Latitude, Longitude, and Radius of Addresses for #{$basefile}:"
puts "--------------------------------------------------------------"

csv_data.each do |child|

  puts "#{child[:latitude]}, #{child[:longitude]}, #{child[:radius]}"

  # Pulls child data from hash for lat/long/radius
  lat = child[:latitude]
  lon = child[:longitude]
  rad = child[:radius]

  # Converts radius to meters for geohex calc
  meters = rad.to_f*1609.34

  # Finds coverage area withing radius of lat/long
  cov = GeoHex::Coverage.new(lat, lon)

  # Grabs GeoHexes within coverage area and converts it to SQL-friendly text
  for hex in cov.within(meters)
    hex = "'#{hex}',"
    gh_array << [hex]
  end
end

# Removes duplicate geohexes from result
gh_array = gh_array.uniq

# Displays information
puts ""
puts "Unique GeoHex Results for #{$basefile}:"
puts "--------------------------------------------------------------"
puts gh_array

# Exports GeoHexes to CSV using the account name
create_csv_for_GH(gh_array)