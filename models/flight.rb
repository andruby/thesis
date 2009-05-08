# just a structure to hold all the data, 
# logic and algorithm should be in a different file
class Flight < Struct.new(:id, :original_aircraft, :flight_nr_1, :flight_nr_2, :haul, :departure_time, :arrival_time, :flight_time, :demand_1, :demand_2, :assigned_aircraft)
  attr_accessor :schedule_location
  
  def aircraft
    (self.assigned_aircraft || self.original_aircraft)
  end
  
  def assign_aircraft(aircraft)
    self.assigned_aircraft = aircraft
  end
  
  # passengers spilled over both legs
  def spill
    ([capacity,demand_1].max-capacity)+([capacity,demand_2].max-capacity)
  end
  
  # the highest loadfactor of both legs
  def load_factor
    max_demand / capacity.to_f
  end
  
  # Aircraft passenger capacity
  def capacity
    self.aircraft.passenger_capacity
  end
  
  # maximale vraag
  def max_demand
    [demand_1,demand_2].max
  end
  
  # prijs van een ticket
  def price
    haul == "Medium" ? Assignment::params[:price_medium] : Assignment::params[:price_short]
  end
  
  # profit
  def profit(aircraft_type=self.aircraft)
    winst = 0
    [demand_1,demand_2].each do |demand|
      if aircraft_type.passenger_capacity >= demand
        # de vraag wordt voldaan
        winst += price * demand
      else
        winst += price * aircraft_type.passenger_capacity
      end
    end
    # Kosten aftrekken
    winst -= 2 * aircraft_type.fixed_cost * Assignment::params[:fixed_cost_100]
    winst -= (flight_time/60) * Assignment::params[:var_cost_100] * aircraft_type.var_cost
    return winst
  end
end