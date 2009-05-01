require 'config.rb'
require 'file_configer.rb'
require 'benchmark'
require 'activesupport'

config_file = FileConfiger.new('ilog/data.dat', ['// START_',''],['// STOP_',''])

START_OF_WEEK = Date.parse("02FEB2009")
END_OF_WEEK = Date.parse("08FEB2009")

# Find all airports within a certain distance of Brussels
bru = Airport.find_by_iata_code('BRU')
airports = Airport.find(:all, :origin => bru, :within => 1000).collect(&:iata_code)
airport_ids = airports.collect { |iata| Airport.find_by_iata_code(iata).id }

# Write the airports
config_file.queue_replace('AIRPORTS',"Airports = { Source #{airports.join(' ')} Sink };")

# Fing all the flight leg groups going from those airport or to those airports
legs = FlightLegGroup.find(:all, :conditions => {:departure_airport_id => airport_ids, :arrival_airport_id => airport_ids})

puts "Starting to render legs"
max_arrival_mins = [0,nil]

leg_data = "flightLegs = {\n"
id_count = -1
bm = Benchmark.measure do
  #  id, dep, d_time, arr, a_time, type, demand, price
  # < 1, ABZ, 202, NWI, 452, Medium, 119, 1000>
  legs.each do |leg|
    # skip maintenance stuff
    next if leg.distance < 5 
    demand = (30+rand()*80).floor
    price = (leg.distance * (rand() * 0.5 + 0.75)).floor
    type = case (leg.distance)
    when 0..2000 then "Short"
    when 2000..4000 then "Medium"
    else
      "Long"
    end
    #puts "distance: #{leg.distance} - type: #{type}"
    leg.dates(START_OF_WEEK,END_OF_WEEK).each do |date|
      wday = date.cwday
      max_arrival_mins = [leg.arrival_minutes(wday),leg.id] if leg.arrival_minutes(wday) > max_arrival_mins.first
      leg_data << "< #{id_count+=1}, #{leg.departure_airport.iata_code}, #{leg.departure_minutes(wday)}, #{leg.arrival_airport.iata_code}, #{leg.arrival_minutes(wday)}, #{type}, #{demand}, #{price}>\n"
      raise "Error: #{leg.departure_minutes(wday)} is not before #{leg.arrival_minutes(wday)}" if leg.departure_minutes(wday) > leg.arrival_minutes(wday)
    end # weekday
  end # leg
end # benchmark

leg_data << "};"

puts "max arrival mins: #{max_arrival_mins.first} (id: #{max_arrival_mins.last})"
puts "leg count = #{id_count}"

puts bm

config_file.queue_replace('FLIGHTLEGS',leg_data)
config_file.write_it