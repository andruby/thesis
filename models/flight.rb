# just a structure to hold all the data, 
# logic and algorithm should be in a different file
class Flight < Struct.new(:id, :original_aircraft, :flight_nr_1, :flight_nr_2, :haul, :departure_time, :arrival_time, :flight_time, :demand_1, :demand_2, :price)

end