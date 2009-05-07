require 'config'
require 'yaml'

################
# Configuratie #
################

# save file voor vluchten
yaml_file = 'data/flights.yml'

# kosten parameters
fixed_cost_100 = 3000 / 100.0
var_cost_100 = 50 / 100.0
price = {"Short"=>100,"Medium"=>200}

# rotatietijd
min_rotatie_tijd = 30.minutes

#--------------#

class GeenInlegException < Exception; end;

if false && File.exist?(yaml_file)
  puts "loading from Yaml"
  flights = File.open( yaml_file ) { |yf| YAML::load( yf ) }
else
  START_OF_PERIOD = Date.parse("14SEP2008")
  END_OF_PERIOD  = START_OF_PERIOD  + 6.days

  puts "#{START_OF_PERIOD} tot #{END_OF_PERIOD}"

  bru = Airport.find_by_iata_code('BRU')
  out_legs = bru.flight_leg_groups_out.collect { |flg| flg.flight_legs(START_OF_PERIOD,END_OF_PERIOD) }.flatten.sort_by(&:departure_time)
  in_legs = bru.flight_leg_groups_in.collect { |flg| flg.flight_legs(START_OF_PERIOD,END_OF_PERIOD) }.flatten.sort_by(&:departure_time)

  puts "#{out_legs.size} uitgaande legs"
  puts "#{in_legs.size} inkomende legs"

  flights = []
  id = 0
  errors = 0

  out_legs.each do |out_leg|
    begin
      # inkomende leg zoeken die van zelfde vliegveld vertrekt en na de aankomsttijd + rotatie tijd opstijgt.
      in_leg = in_legs.detect {|in_leg| in_leg.departure_airport == out_leg.arrival_airport && (out_leg.arrival_time + min_rotatie_tijd) <= in_leg.departure_time }
      # gevonden leg uit beschikbaren weghalen
      in_legs -= [in_leg]
      puts "#{in_legs.size} in legs size"
      raise GeenInlegException unless in_leg
      # flight time berekenen
      total_flight_time = (out_leg.arrival_time - out_leg.departure_time) + (in_leg.arrival_time - in_leg.departure_time)
      # flight vullen
      flights << Flight.new(id,out_leg.original_aircraft,out_leg.flight_nr,in_leg.flight_nr,out_leg.haul,
                              out_leg.departure_time,in_leg.arrival_time,total_flight_time,out_leg.demand,in_leg.demand,out_leg.price)
      #p flights.last
      id+=1
    rescue GeenInlegException => e
      puts "Geen inkomende leg gevonden voor deze uitgaande leg:"
      p out_leg
      errors+=1
    end
  end
  puts "Errors: #{errors}, total flights: #{flights.size}"

  puts "Save to yaml file"
  
  File.open(yaml_file,'w') do |file|
    YAML.dump(flights,file)
  end
end


# Winst berekening
puts "calculating original objective function:"
omzet = 0
fixed_cost = 0
var_cost = 0
spill = {"Short" => 0, "Medium" => 0}

flights.each do |flight|
  [flight.demand_1,flight.demand_2].each do |demand|
    if flight.original_aircraft.passenger_capacity >= demand
      # de vraag wordt voldaan
      omzet += price[flight.haul] * demand
    else
      # er is spill
      omzet += price[flight.haul] * flight.original_aircraft.passenger_capacity
      spill[flight.haul] += demand - flight.original_aircraft.passenger_capacity
    end
  end
  # Kosten toevoegen
  fixed_cost += 2 * flight.original_aircraft.fixed_cost * fixed_cost_100
  var_cost += (flight.flight_time/60) * var_cost_100 * flight.original_aircraft.var_cost
end

winst = omzet - fixed_cost - var_cost
puts "R: #{omzet}\tFC: #{fixed_cost.round}\tVC: #{var_cost.round}\t Winst: #{winst.round}"
puts "spill: " + spill.inspect
