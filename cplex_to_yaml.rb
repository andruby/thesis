require 'config'

flights_yaml = 'data/flight_for_cplex.yml'
flights_write_yaml = 'data/flight_from_cplex.yml'

flights = load_from_yaml(flights_yaml)

cplex_txt = '/Volumes/andrew/unief/thesis - fleet assignment/ruby/ilog/cplex_assignment.txt'

cplex_2_ba = {
  "AR1" => "AR1",
  "AR8" => "AR8",
  "B73" => "733",
  "B74" => "734",
  "A19" => "319"
}

puts "extracting cplex assignments"

cplex_hash = {}
File.open(cplex_txt,'r') do |file|
  while(line = file.gets)
    id, plane = line.strip.split(' - ')
    id = id.scan(/\d+/).first.to_i
    ba_code = cplex_2_ba[plane.gsub('by: ','')]
    cplex_hash[id] = AircraftType.find_by_ba_code(ba_code)
  end
end

puts "assigning aircraft"

flights.each do |flight|
  flight.assign_aircraft(cplex_hash[flight.id])
  raise "NotFound id: #{flight.id}" unless cplex_hash[flight.id]
end

puts "writing the yaml"
write_to_yaml(flights,flights_write_yaml)