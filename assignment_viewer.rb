require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # load different parameters
  AssignmentParameters.from_ilog('lower_spill_cost')
  
  # save file voor vluchten
  session_name = 'week_14_20'
  cplexed = "data/assignments/#{session_name}_assigned.yml"
  cplexed_2 = "data/assignments/#{session_name}_assigned_2.yml"
  original = "data/assignments/#{session_name}_flights.yml"
  swapped = "data/assignments/flights_swapped_1420.yml"

  # load flights
  @flights = load_from_yaml(original)
  
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