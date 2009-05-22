# 
# Visualisatie software. Geschreven als Sinatra webapplicatie. http://www.sinatrarb.com/
# Online versie op http://thesis.andrewsblog.org
#

require 'rubygems'
require 'sinatra'
require 'config'

get '/' do
  # alle mogelijke datasets
  @datasets = {'A' => '7_13', 'B' => '14_20', 'C' => '21_27', 'D' => '7_27'}
  @configs = (1..7).to_a
  @mode = %w{cplex swapped original}
  
  config_folder = File.dirname(__FILE__) + '/Assignments'
  
  # standaard params
  params[:dataset] ||= 'B'
  params[:config] ||= 1
  params[:mode] ||= 'cplex'
  
  # bouw filename
  @yaml_file = config_folder+"/#{@datasets[params[:dataset]]}"
  @yaml_file += "_conf#{params[:config]}" unless params[:mode] == 'original'
  @yaml_file += "_#{params[:mode]}.yml"

  # controleer of het bestand bestaat
  return "File not found: #{@yaml_file}" unless File.exists?(@yaml_file)
  
  # load the parameters
  AssignmentParameters.from_ilog("config_#{params[:config]}")

  # load flights
  @flights = load_from_yaml(@yaml_file)
  
  # assign flights to aircraft
  @assignment = Assignment.new(@flights)
  @assignment.schedule!
  @results = @assignment.results
  @original_results = @assignment.results(true)
  
  # show a flight
  @flight = @flights[5]
  
  # tel swaps 
  @fam_swaps, @nonfam_swaps = @assignment.swap_count
  
  # pixels nodig voor de schedule table
  @first_day = @flights.sort_by(&:departure_time).first.departure_time.to_date
  @last_day = @flights.sort_by(&:arrival_time).last.arrival_time.to_date
  days_needed = (@last_day - @first_day).to_i + 1
  # 1 pixel is 5 minuten, dus 12 pixels zijn 1 uur en 12*24 pixels 1 dag
  @pixels_needed = days_needed*24*12
  
  # bereken de bronnen van de kostenreductie
  orig_real_k = @original_results[:var_cost] + @original_results[:fixed_cost]
  new_real_k = @results[:var_cost] + @results[:fixed_cost]
  k_redux = (orig_real_k - new_real_k)
  spill_redux = (@original_results[:spill_cost] - @results[:spill_cost])
  swap_penalty =  @results[:swap_cost] 
  # totale kostenreductie, swap penalty moet er bij
  total = (@original_results[:total_cost] - @results[:total_cost])
  total_no_swap = total + swap_penalty
  total_no_swap = 0.000001 if total_no_swap == 0
  percent_total_no_swap = (total_no_swap/@original_results[:total_cost].to_f)
  @percent_operationeel = ((k_redux/total_no_swap.to_f)*percent_total_no_swap*100).round(2)
  @percent_spill = ((spill_redux/total_no_swap.to_f)*percent_total_no_swap*100).round(2)
  @percent_swap = ((swap_penalty/total_no_swap.to_f)*percent_total_no_swap*100).round(2)

  # render de html template in views/flight_table_view.erb
  erb :flight_table_view
end

# Helpers voor het formateren van de html
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