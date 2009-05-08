require 'benchmark'

#
# Probleem: het kan gebeuren dat flights niet meer passen na random gefoefel!
#

class Assignment
  def filler_algorithm!
    # sort flights from lowest demand to highest demand
    @flights = @flights.sort_by(&:max_demand)
    
    # sort fleet types from lowest capacity to highest
    @fleet_capacity_matrix = @available_craft.collect { |a| [a,a.passenger_capacity.to_i] }.sort_by(&:last)
    
    fleets_size = @fleet_capacity_matrix.size
    
    @flights.collect! do |flight| 
      assigned = false
      
      x = -1
      # try to assign it to the fleet that *just* fits the demand
      begin
        x += 1
        fleet = @fleet_capacity_matrix[x].first
        capacity = @fleet_capacity_matrix[x].last
        # check if capacity fullfills maximum demand
        if flight.max_demand <= capacity && @fleets[fleet.ba_code].fits?(flight)
          flight.assign_aircraft(fleet) 
          @fleets[fleet.ba_code].fit_flight(flight)
          assigned = true
          puts "assigned flight id #{flight.id} (#{flight.max_demand}) to fleet ba #{flight.aircraft.ba_code} (#{flight.aircraft.passenger_capacity})"
        end
      end until assigned || (@fleet_capacity_matrix[x+1].nil?)
      
      # if it still hasn't been assigned, which means there will be spill
      # try to assign it from the biggest -> smallest fleet type
      x = fleets_size
      while assigned == false && x >= 1
        x -= 1
        fleet = @fleet_capacity_matrix[x].first
        if @fleets[fleet.ba_code].fits?(flight)
          # assign the vleet type to the flight
          flight.assign_aircraft(fleet)
          @fleets[fleet.ba_code].fit_flight(flight)
          assigned = true
        end # if
      end # while
      
      flight
    end # sorted_flights.collect
  end
end

Benchmark.bm(12) do |bench|
  bench.report("Config:") do
    require 'config'
  end
  bench.report("Loading:") do
    @assignment = Assignment.new(load_from_yaml('data/flights_1_9.yml'))
  end
  bench.report("Filler:") do
    @assignment.filler_algorithm!
  end
  bench.report("Winst:") do
    p @assignment.results
  end
  bench.report("Schedule:") do
    @assignment.schedule!(true)
  end
  bench.report("Winst(2):") do
    p @assignment.results
  end
  bench.report("WriteYaml:") do
    write_to_yaml(@assignment.flights,'data/assignments/flights.yml')
  end
end