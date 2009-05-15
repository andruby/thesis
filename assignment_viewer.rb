require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # load different parameters
  AssignmentParameters.from_ilog('lower_spill_cost')
  
  # lijst met bestanden samenstellen
  @configs = []
  config_folder = File.dirname(__FILE__) + '/data/assignments'
  Dir[config_folder+'/*.yml'].each{ |d| @configs << File.basename(d,'.yml') }
  
  # vorige lijst
  session_name = 'week_14_20'
  cplexed = "data/assignments/#{session_name}_assigned.yml"
  cplexed_2 = "data/assignments/#{session_name}_assigned_2.yml"
  original = "data/assignments/#{session_name}_flights.yml"
  swapped = "data/assignments/flights_swapped_1420.yml"

  yaml_file = (params[:yaml_file] ? File.join(config_folder,params[:yaml_file] + '.yml') : original)

  # load flights
  @flights = load_from_yaml(yaml_file)
  
  # assign flights to aircraft
  @assignment = Assignment.new(@flights)
  @assignment.schedule!
  @results = @assignment.results

  erb :flight_table_view
end

helpers do
  def d_format(digit)
    digit.round.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1.")
  end
end