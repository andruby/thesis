require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # save file voor vluchten
  session_name = 'week_14_20'
  yaml_file = "data/assignments/#{session_name}_assigned.yml"
  yaml_file_2 = "data/assignments/#{session_name}_flights.yml"

  # load flights
  @flights = load_from_yaml(yaml_file_2)
  
  # assign flights to aircraft
  @assignment = Assignment.new(@flights)
  @assignment.schedule!
  @results = @assignment.results
  #p @assignment.fleets['AR1'].schedules.first.flights.collect{|f| [f.departure_time,f.arrival_time]}
    
  erb :flight_table_view
end

helpers do
  def d_format(digit)
    digit.round.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1.")
  end
end