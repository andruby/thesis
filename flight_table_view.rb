require 'yaml'
require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # save file voor vluchten
  yaml_file = 'data/flights.yml'

  # load flights
  @flights = File.open( yaml_file ) { |yf| YAML::load( yf ) }
  @aircraft_types = AircraftType.find(:all, :conditions => ["count > 0"], :order => "id")
  
  # assign flights to aircraft
  @assignment = Assignment.new(@flights,@aircraft_types)
  @assignment.schedule!(30*60)
  #p @assignment.fleets['AR1'].schedules.first.flights.collect{|f| [f.departure_time,f.arrival_time]}
    
  erb :flight_table_view
end