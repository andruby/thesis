require 'config'

connect_to_db

################
# Configuratie #
################

# Load default parameters
AssignmentParameters.from_ilog("config_1")

# flights initialiseren
start_date = Date.parse("21SEP2008")
end_date = start_date + 6.days
session_name = "#{start_date.day}_#{end_date.day}"
flights = Flights.new(session_name,start_date,end_date)

# also save as yaml
yaml_file = ("data/assignments/#{session_name}_original.yml")

################
  
puts "#{flights.start_date} tot #{flights.end_date}"  

bru = Airport.find_by_iata_code('BRU')
out_legs = bru.flight_leg_groups_out.collect { |flg| flg.flight_legs(flights.start_date,flights.end_date) }.flatten.sort_by(&:departure_time)
in_legs = bru.flight_leg_groups_in.collect { |flg| flg.flight_legs(flights.start_date,flights.end_date) }.flatten.sort_by(&:departure_time)

puts "#{out_legs.size} uitgaande legs"
puts "#{in_legs.size} inkomende legs"

id = 0
errors = 0

out_legs.each do |out_leg|
  begin
    # inkomende leg zoeken die van zelfde vliegveld vertrekt en na de aankomsttijd + rotatie tijd opstijgt.
    in_leg = in_legs.detect {|in_leg| in_leg.departure_airport == out_leg.arrival_airport && 
                                      (out_leg.arrival_time + AssignmentParameters.rotation_time_external) <= in_leg.departure_time && 
                                      in_leg.arrival_time.to_date <= flights.end_date }
    if in_leg
      in_legs -= [in_leg]

      # flight time berekenen
      total_flight_time = (out_leg.arrival_time - out_leg.departure_time) + (in_leg.arrival_time - in_leg.departure_time)
      # flight vullen
      flights[id] = Flight.new(id,out_leg.original_aircraft,out_leg.flight_nr,in_leg.flight_nr,out_leg.haul,out_leg.departure_time,
                              in_leg.arrival_time,total_flight_time,out_leg.demand,in_leg.demand,out_leg.demand_28d_before,in_leg.demand_28d_before)
      id+=1
    end
  end
end

puts "total flights: #{flights.size}"
puts "Save to ilog file"
flights.to_ilog
puts "Save to yaml file"
write_to_yaml(flights,yaml_file)
