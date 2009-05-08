require 'config.rb'
require 'file_configer.rb'
require 'activesupport'

config_file = FileConfiger.new('/Volumes/andrew/unief/thesis - fleet assignment/ruby/ilog/data_2.dat', ['// START_',''],['// STOP_',''])

flights_yaml = 'data/flight_for_cplex.yml'

min_rotatie_tijd = 30.minutes

START_OF_PERIOD = Date.parse("14SEP2008")
start_of_week_in_time = START_OF_PERIOD.to_time
END_OF_PERIOD  = START_OF_PERIOD  + 6.days

puts "#{START_OF_PERIOD} tot #{END_OF_PERIOD}"

bru = Airport.find_by_iata_code('BRU')
out_legs = bru.flight_leg_groups_out.collect { |flg| flg.flight_legs(START_OF_PERIOD,END_OF_PERIOD) }.flatten.sort_by(&:departure_time)
in_legs = bru.flight_leg_groups_in.collect { |flg| flg.flight_legs(START_OF_PERIOD,END_OF_PERIOD) }.flatten.sort_by(&:departure_time)

# all airports
airports = bru.flight_leg_groups_out.collect { |flg| flg.arrival_airport.iata_code }.uniq.sort
p airports
config_file.queue_replace('AIRPORTS',"Airports = { Source #{airports.join(' ')} Sink };")

puts "#{out_legs.size} uitgaande legs"
puts "#{in_legs.size} inkomende legs"

flights = []
id = 1
errors = 0
good_out_legs = []
good_in_legs = []

out_legs.each do |out_leg|
  # inkomende leg zoeken die van zelfde vliegveld vertrekt en na de aankomsttijd + rotatie tijd opstijgt.
  in_leg = in_legs.detect {|in_leg| in_leg.departure_airport == out_leg.arrival_airport && 
                                    (out_leg.arrival_time + min_rotatie_tijd) <= in_leg.departure_time && 
                                    in_leg.arrival_time.to_date <= END_OF_PERIOD }
  if in_leg
    in_legs -= [in_leg]
    good_in_legs << in_leg
    good_out_legs << out_leg
    
    # flight time berekenen
    total_flight_time = (out_leg.arrival_time - out_leg.departure_time) + (in_leg.arrival_time - in_leg.departure_time)
    # flight vullen
    flights << Flight.new(id,out_leg.original_aircraft,out_leg.flight_nr,in_leg.flight_nr,out_leg.haul,
                            out_leg.departure_time,in_leg.arrival_time,total_flight_time,out_leg.demand,in_leg.demand)
    #p flights.last
    id+=1
  end
end

puts "good in legs: #{good_in_legs.size}"
puts "good out legs: #{good_out_legs.size}"

puts "Save flights to yaml file"
write_to_yaml(flights,flights_yaml)

i=0
leg_data = "flightLegs = {\n"

(good_out_legs+good_in_legs).each do |leg|
  dep_minutes = ((leg.departure_time - start_of_week_in_time)/60).round
  arr_minutes = ((leg.arrival_time - start_of_week_in_time)/60).round
  data_line = "<#{i+=1}, #{leg.departure_airport.iata_code}, #{dep_minutes}, #{leg.arrival_airport.iata_code}, #{arr_minutes}, #{leg.haul}, #{leg.demand}, #{leg.price}>"
  puts data_line
  leg_data << data_line + "\n"
end

leg_data << "};"

config_file.queue_replace('FLIGHTLEGS',leg_data)
config_file.write_it