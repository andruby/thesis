require 'yaml'
require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # save file voor vluchten
  yaml_file = 'data/flights.yml'

  # load flights
  @flights = File.open( yaml_file ) { |yf| YAML::load( yf ) }
  @aircraft_types = AircraftType.all
  
  erb :flight_table_view
end