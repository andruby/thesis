require 'config'

################
# Configuratie #
################

# save file voor vluchten
yaml_file = 'data/flights_1_9.yml'

# kosten parameters (staat nu in Assignment.results)
# fixed_cost_100 = 3000 / 100.0
# var_cost_100 = 50 / 100.0
# price_short = 100
# price_medium = 200

# rotatietijd
min_rotatie_tijd = 30.minutes

#--------------#

class GeenInlegException < Exception; end;

if File.exist?(yaml_file)
  puts "loading from Yaml"
  flights = load_from_yaml(yaml_file)
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
  
  write_to_yaml(flights,yaml_file)
end


# Winst berekening
puts "calculating original objective function:"
assignment = Assignment.new(flights)
results = assignment.results()

puts "R: #{results[:omzet]}\tFC: #{results[:fixed_cost].round}\tVC: #{results[:var_cost].round}\t Winst: #{results[:winst].round}"
puts "spill: " + results[:spill].inspect
