class FlightLeg
  attr_accessor :group_id, :original_aircraft, :flight_nr, :distance, :aircraft_id, :haul
  attr_accessor :departure_airport, :departure_time, :arrival_airport, :arrival_time, :demand, :price
  
  def initialize(params={})
    params.each_pair { |key,value| self.instance_variable_set(:"@#{key}",value) }
  end
  
  def self.from_flg(flg,date)
    leg = FlightLeg.new
    leg.flight_nr = flg.flight_nr
    leg.departure_time = add_date_time(date,flg.departure_time)
    # 1 dag toevoegen als het aankomst uur voor het vertrek uu is
    arrival_date = date + (flg.arrival_time < flg.departure_time ? 1 : 0)
    leg.arrival_time = add_date_time(arrival_date,flg.arrival_time)
    leg.departure_airport = flg.departure_airport
    leg.arrival_airport = flg.arrival_airport
    leg.haul = (flg.arrival_airport.haul || flg.departure_airport.haul)
    # leg.distance = flg.distance.to_i
    leg.original_aircraft = flg.aircraft_type
    return leg
  end
  
  def medium_haul?
    haul == "Medium"
  end
  
  # verwachte vraag op vertrekdag
  def demand
    # regressie toepassen uit analyse
    (demand_at_days_before(28) * 0.9526 + 29.8462).round
  end
  
  # geregistreerde vraag X dagen voor het vertrek
  def demand_at_days_before(number_of_days)
    date = departure_time.to_date - number_of_days.days
    flight_nr_date = "#{flight_nr.gsub('SN','SN ')}_#{departure_time.day}"
    until sales_leg = SalesLeg.find_by_flight_nr_date(flight_nr_date) do
      puts "WARNING: NoSalesLegFound: Flight_nr_date #{flight_nr_date}" unless sales_leg
      flight_nr_date = flight_nr_date.next
    end
    return sales_leg.sales_ticks.find_by_date(date).seats_sold
  end
  
  # Ticket price
  # 300eur for medium haul, 200eur for short haul
  def price
    medium_haul? ? 300 : 200
  end
  
  private
    def self.add_date_time(date,time)
      Time.mktime(date.year,date.mon,date.day,time.hour,time.min)
    end
    
    def self.random_demand
      # gives a random demand between 50 and 125
      50+rand()*75
    end
end