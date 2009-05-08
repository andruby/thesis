# just a structure to hold all the data, 
# logic and algorithm should be in a different file
class Flight < Struct.new(:id, :original_aircraft, :flight_nr_1, :flight_nr_2, :haul, :departure_time, :arrival_time, :flight_time, :demand_1, :demand_2, :price)
  attr_accessor :assigned_aircraft
  attr_accessor :location_in_schedule
  
  def aircraft
    (@assigned_aircraft || self.original_aircraft)
  end
  
  # passengers spilled over both legs
  def spill
    ([capacity,demand_1].max-capacity)+([capacity,demand_2].max-capacity)
  end
  
  # the highest loadfactor of both legs
  def load_factor
    [demand_1,demand_2].max / capacity.to_f
  end
  
  # Aircraft passenger capacity
  def capacity
    self.aircraft.passenger_capacity
  end
end