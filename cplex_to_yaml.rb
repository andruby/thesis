require 'config'

session_name = 'week_14_20'
flights_yaml = "data/assignments/#{session_name}_flights.yml"
flights_write_yaml = "data/assignments/#{session_name}_assigned_2.yml"

flights = load_from_yaml(flights_yaml)

cplex_txt = '/Volumes/andrew/unief/thesis - fleet assignment/ILOG/shared_data/assignments/assignments.txt'

puts "extracting cplex assignments"

cplex_hash = {}
File.open(cplex_txt,'r') do |file|
  while(line = file.gets)
    id, ba_code = line.strip.split(': ')
    id = id.to_i
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