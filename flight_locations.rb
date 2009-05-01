require 'config.rb'

# aantal punten in de cirkel
circle_resolution = 100

# ranges voor het trekken van de cirkel [kms, kleur]
ranges = [[2000,"F20600"],
          [3800,"BF0500"],
          [8400,"720300"]]

require 'file_configer.rb'

config_file = FileConfiger.new('map/flight_routes.xml')

# airports uit de database halen
airports = Airport.all
bru = Airport.find_by_iata_code('BRU')

# airport dots berekenen
airport_data = (airports-[bru]).collect { |a|
  dist = a.distance_from(bru,:units=>:kms)
  color = ranges.detect {|r| (dist < r.first ? r.last : nil) }
  "\t\t<movie color='#{color}' file='circle' title='#{a.city} (#{a.iata_code})' lat='#{a.lat}' long='#{a.lng}' width='6' height='6' fixed_size='true'></movie>"
}.join("\n")
config_file.queue_replace('CITIES',airport_data)

# range lines bereken
range_lines = ranges.collect { |range|
  lats, lngs = [], []
  step = 360/circle_resolution.to_f
  start = step/2.to_f
  circle_resolution.times do |x|
    point = bru.endpoint(start+step*x,range.first,:units=>:kms)
    lats << point.lat
    lngs << point.lng
  end
  "\t\t<line lat='#{lats.join(',')}' long='#{lngs.join(',')}' width='1' alpha='80' curved='true' color='#{range.last}'></line>"
}.join("\n")
config_file.queue_replace('LINES',range_lines)

# schrijf de veranderingen weg
config_file.write_it