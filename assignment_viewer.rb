require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # load different parameters
  AssignmentParameters.from_ilog('config_1')
  
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
  @original_results = @assignment.results(true)
  
  # show a flight
  @flight = @flights[727]
  
  # pixels nodig voor de schedule table
  @first_day = @flights.sort_by(&:departure_time).first.departure_time.to_date
  @last_day = @flights.sort_by(&:arrival_time).last.arrival_time.to_date
  days_needed = (@last_day - @first_day).to_i + 1
  # 1 pixel is 5 minuten, dus 12 pixels zijn 1 uur en 12*24 pixels 1 dag
  @pixels_needed = days_needed*24*12

  erb :flight_table_view
end

helpers do
  def d_format(digit)
    digit.round.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1.")
  end
  
  def r_diff(current,original)
    diff = (current - original)/original.to_f*100
    span_class = (diff > 0 ? 'red' : 'green')
    "<span class='#{span_class}'>#{sprintf('%5.2f', diff.round(2))}%</span>"
  end
  
  def a_diff(current,original)
    diff = (current - original)
    span_class = (diff > 0 ? 'red' : 'green')
    "<span class='#{span_class}'>#{diff}</span>"
  end
  
  def result_with_diff(current,original,key)
    "<td align='right'>#{d_format current[key]}</td>
		<td align='right'>#{r_diff current[key],original[key]}</td>"
  end
  
  def result_with_absolute_diff(current,original)
    "<td align='right'>#{d_format current}</td>
		<td align='right'>#{a_diff current,original}</td>"
  end
end