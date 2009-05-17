# just a structure to hold all the data, 
# logic and algorithm should be in a different file
class Flight < Struct.new(:id,:original_aircraft, :flight_nr_1, :flight_nr_2, :haul, :departure_time, :arrival_time, :flight_time, :pax_1, :pax_2, :pax_1_28d, :pax_2_28d, :assigned_aircraft)
  attr_accessor :schedule_location
  
  def aircraft(original=false)
    return self.original_aircraft if original
    (self.assigned_aircraft || self.original_aircraft)
  end
  
  def assign_aircraft(aircraft)
    self.assigned_aircraft = aircraft
  end
  
  def get_28d_demand
    
  end
  
  # passengers spilled over both legs
  def spill
    ([capacity,pax_1].max-capacity)+([capacity,pax_2].max-capacity)
  end
  
  # the highest loadfactor of both legs
  def load_factor
    max_pax / capacity.to_f
  end
  
  # Aircraft passenger capacity
  def capacity(original=false)
    self.aircraft(original).passenger_capacity
  end
  
  # maximale vraag
  def max_pax
    [pax_1,pax_2].max
  end
  
  # naar ILOG formaat
  # <is, depT, arrT, flightT, haul, pax_1, pax_2>
  def to_ilog(id,tijd_nulpunt)
    depT = ((self.departure_time - tijd_nulpunt)/60).round
    arrT = ((self.arrival_time - tijd_nulpunt)/60).round
    "<#{id}, #{depT}, #{arrT}, #{(flight_time/60.0).round}, #{self.haul}, #{self.pax_1}, #{self.pax_2}>"
  end
  
  # from ILOG formaat
  def self.from_ilog(tijd_nulpunt,ilog_txt)
    depT = ((self.departure_time - tijd_nulpunt)/60).round
    arrT = ((self.arrival_time - tijd_nulpunt)/60).round
    "<#{id}, #{depT}, #{arrT}, #{arr_minutes}, #{(flight_time/60.0).round}, #{self.haul}, #{self.pax_1}, #{self.pax_2}>"
  end
  
  # prijs van een ticket
  def price
    haul == "Medium" ? AssignmentParameters.spill_medium : AssignmentParameters.spill_short
  end
  
  # cost of assigning given aircraft to this flight
  def cost(aircraft_type=self.aircraft)
    cost = 0
    [pax_1,pax_2].each do |pax|
      if pax >= aircraft_type.passenger_capacity
        # er is spill
        cost += price * (pax - aircraft_type.passenger_capacity)
      end
    end
    # Kosten aftrekken
    cost += 2 * (aircraft_type.fixed_cost/100.0) * AssignmentParameters.fixed_cost_100
    cost += (flight_time/(60*60)) * AssignmentParameters.var_cost_100 * (aircraft_type.var_cost/100.0)
    return cost
  end
end