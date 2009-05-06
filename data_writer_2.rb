require 'config.rb'
require 'file_configer.rb'
require 'benchmark'
require 'activesupport'

config_file = FileConfiger.new('ilog/data_2.dat', ['// START_',''],['// STOP_',''])

START_OF_WEEK = Date.parse("18SEP2008")
start_of_week_in_time = START_OF_WEEK.to_time
END_OF_WEEK = START_OF_WEEK + 6.days

puts "#{START_OF_WEEK} tot #{END_OF_WEEK}"

# all airports
airports = Airport.all.collect{ |a| a.iata_code }
config_file.queue_replace('AIRPORTS',"Airports = { Source #{airports.join(' ')} Sink };")

# tel totaal aantal flight legs
groups = FlightLegGroup.all
puts "groups count: #{groups.size}"

legs = []
groups.each do |flg|
  legs += flg.flight_legs(START_OF_WEEK,END_OF_WEEK)
end
puts "legs count: #{legs.size}"

i=0
leg_data = "flightLegs = {\n"

legs.each do |leg|
  dep_minutes = ((leg.departure_time - start_of_week_in_time)/60).round
  arr_minutes = ((leg.arrival_time - start_of_week_in_time)/60).round
  data_line = "<#{i+=1}, #{leg.departure_airport}, #{dep_minutes}, #{leg.arrival_airport}, #{arr_minutes}, #{leg.haul}, #{leg.demand}, #{leg.price}>"
  puts data_line
  leg_data << data_line + "\n"
end

leg_data << "};"

config_file.queue_replace('FLIGHTLEGS',leg_data)
config_file.write_it