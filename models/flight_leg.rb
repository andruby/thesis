class FlightLeg
  attr_accessor :group_id, :original_aircraft_id, :flight_nr, :distance, :aircraft_id
  attr_accessor :departure_airport, :departure_time, :arrival_airport, :arrival_time, :demand, :price
  
  def initialize(params={})
    params.each_pair { |key,value| self.instance_variable_set(:"@#{key}",value) }
  end
  
  def self.from_flg(flg,date)
    leg = FlightLeg.new
    leg.flight_nr = flg.flight_nr
    leg.departure_time = add_date_time(date,flg.departure_time)
    leg.arrival_time = add_date_time(date,flg.arrival_time)
    leg.departure_airport = flg.departure_airport.iata_code
    leg.arrival_airport = flg.arrival_airport.iata_code
    leg.distance = flg.distance.to_i
    leg.original_aircraft_id = flg.aircraft_type.id
    leg.demand = random_demand
    leg.price = random_price(leg.distance)
    return leg
  end
  
  private
    def self.add_date_time(date,time)
      Time.mktime(date.year,date.mon,date.day,time.hour,time.min)
    end
    
    def self.random_demand
      # gives a random demand between 50 and 125
      50+rand()*75
    end
    
    def self.random_price(distance)
      case distance
      when 0..500 
        300
      when 500..1000
        400
      when 1000..3000
        600
      else
        800
      end   
    end
end