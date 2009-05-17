require 'benchmark'
require 'config'

session_name = '14_20'
config = 1

AssignmentParameters.from_ilog("config_#{config}")

# All the extra methods required
# to run the swapping algorithm
class Assignment
  
  # check if the swap of both flights fits in the scedule
  def swap_fits?(flight_1,flight_2)
    schedule_for(flight_2).remove_flight(flight_2)
    fit = schedule_for(flight_2).fits?(flight_1)
    schedule_for(flight_2).add_flight(flight_2)
    return fit
  end
  
  # check if a swap is valid
  def swap_valid?(flight_1,flight_2)
    # check range constraint
    return false if (flight_1.haul == "Medium" && flight_2.aircraft.range == "Short")
    return false if (flight_2.haul == "Medium" && flight_1.aircraft.range == "Short")
    # check schedule constraint
    return (swap_fits?(flight_1,flight_2) && swap_fits?(flight_2,flight_1))
  end

  # winst in kostenreductie als gevolg van de swap
  def swap_profits(flight_1,flight_2)
    aircraft_1 = flight_1.aircraft
    aircraft_2 = flight_2.aircraft
    delta_1 = flight_1.cost(aircraft_1) - flight_1.cost(aircraft_2) 
    delta_2 = flight_2.cost(aircraft_2) - flight_2.cost(aircraft_1)
    return (delta_1 + delta_2)
  end
  
  def do_swap!(flight_1,flight_2)
    @swap_counter += 1
    print '.'
    STDIN.flush
    # save previous schedules
    sched_1 = schedule_for(flight_1)
    sched_2 = schedule_for(flight_2)
    # remove flights
    sched_2.remove_flight(flight_2)
    sched_1.remove_flight(flight_1)
    # add flights
    sched_1.add_flight(flight_2)
    sched_2.add_flight(flight_1)
    # swap assigned aircraft type
    aircraft_2 = flight_2.aircraft
    flight_2.assign_aircraft(flight_1.aircraft)
    flight_1.assign_aircraft(aircraft_2)
  end
  
  # return the possible swaps for a flight, sorted by profitability
  def swaps_for_flight(flight_1)
    possible_swaps = []
    @flights.each do |flight_2|
      if ((profits = swap_profits(flight_1,flight_2)) > 1) && swap_valid?(flight_1,flight_2)
        possible_swaps << [profits,flight_2]
      end
    end
    return nil if possible_swaps.empty?
    possible_swaps.sort_by(&:first)
  end
    
  # execute the most profitable swap for a given flight
  def best_swap_for_flight(flight_1)
    swaps = swaps_for_flight(flight_1)
    do_swap!(flight_1,swaps.last.last) if swaps
  end
  
  # do a full swap pass and return the number of swaps executed
  def full_swap_pass
    @swap_counter = 0
    @flights.each do |flight|
      best_swap_for_flight(flight)
    end
    return @swap_counter
  end
end

@pass_counter = 0
@pass_results = []

# Shortcut to keep the execution time of a swapping pass
def do_a_pass(assignment)
  start_time = Time.now
  swap_count = assignment.full_swap_pass
  @pass_results << {:pass => @pass_counter+=1,:swap_count => swap_count,:time_ran => Time.now - start_time,:results => assignment.results}
end

Benchmark.bm(12) do |bench|
  bench.report("Config:") do
    require 'config'
  end
  bench.report("Loading:") do
    @assignment = Assignment.new(load_from_yaml("data/assignments/#{session_name}_original.yml"))
  end
  bench.report("Schedule:") do
    @assignment.schedule!
    @flight_1 = @assignment.flight_with_id(181)
    @flight_2 = @assignment.flight_with_id(186)
    @pass_results << {:pass => 'original',:results => @assignment.results}
  end
  @x = 0
  begin
    bench.report("Pass #{@x+=1}:\n") do
      do_a_pass(@assignment)
    end 
  end until @pass_results.last[:swap_count] < 1
  bench.report("WriteYaml:") do
    puts "results"
    p @pass_results
    write_to_yaml(@assignment.flights,"data/assignments/#{session_name}_conf#{config}_swapped.yml")    
    write_to_yaml(@pass_results,"data/progress_reports/#{session_name}_conf#{config}_swapped.yml")
  end
end