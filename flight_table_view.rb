require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # save file voor vluchten
  yaml_file = 'data/flights.yml'
  yaml_2_file = 'data/assignments/flights.yml'

  # load flights
  @flights = load_from_yaml(yaml_2_file)
  
  # assign flights to aircraft
  @assignment = Assignment.new(@flights)
  @assignment.schedule!(true)
  @results = @assignment.results
  #p @assignment.fleets['AR1'].schedules.first.flights.collect{|f| [f.departure_time,f.arrival_time]}
    
  erb :flight_table_view
end

helpers do
  def d_format(digit)
    digit.round.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1.")
  end
end