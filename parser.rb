require 'config.rb'

# data_file = '../data/W08_flight_Itinerary_feb.txt'
# def parse_flight_legs(txt_file)
#   i=0
#   File.open(txt_file) do |file|
#     while(line = file.gets)
#       array = line.split(/[|\s]+/)
#       if array.size > 5
#         leg = FlightLeg.from_array(array)
#         leg.save!
#         puts "#{i+=1}. #{leg.departure_airport.city} -> #{leg.arrival_airport.city}"
#       end
#     end
#   end
# end

# Version for parsing the new anonymous files
# Flt Desg,Eff Date,Dis Date,Freq,Dept Arp,Dept Time,Arvl Arp,Arrv Time,Subfleet,Service Type
# SN 5129 ,1-sep-08,4-sep-08,12.4...,BRU,07:45,Dest14,09:00,SN  AR8,J
def parse_flight_legs(txt_file)
  i=0
  File.open(txt_file) do |file|
    while(line = file.gets)
      array = line.split(';')
      leg = FlightLegGroup.from_anon_array(array)
      leg.save!
      puts "#{i+=1}. #{leg.departure_airport.iata_code} -> #{leg.arrival_airport.iata_code}"
    end
  end
end

parse_flight_legs('data/flight_schedule.data')
# a= Airport.new
# a.iata_code = 'BRU'
# a.save!
# p a

# doc = Hpricot(open("http://gc.kls2.com/airport/BRU","User-Agent" => "Ruby"))
# p doc.at("abbr.latitude")['title'].to_f