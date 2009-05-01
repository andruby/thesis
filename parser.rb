require 'config.rb'

# data_file = '../data/W08_flight_Itinerary_feb.txt'
def parse_flight_legs(txt_file)
  i=0
  File.open(txt_file) do |file|
    while(line = file.gets)
      array = line.split(/[|\s]+/)
      if array.size > 5
        leg = FlightLeg.from_array(array)
        leg.save!
        puts "#{i+=1}. #{leg.departure_airport.city} -> #{leg.arrival_airport.city}"
      end
    end
  end
end

parse_flight_legs('W08_flight_Itinerary_feb.txt')
# a= Airport.new
# a.iata_code = 'BRU'
# a.save!
# p a

# doc = Hpricot(open("http://gc.kls2.com/airport/BRU","User-Agent" => "Ruby"))
# p doc.at("abbr.latitude")['title'].to_f