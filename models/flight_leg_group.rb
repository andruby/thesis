class FlightLegGroup < ActiveRecord::Base
  belongs_to :departure_airport, :class_name => "Airport", :foreign_key => "departure_airport_id"
  belongs_to :arrival_airport, :class_name => "Airport", :foreign_key => "arrival_airport_id"
  belongs_to :aircraft_type
  
  def self.from_array(array)
    l = FlightLegGroup.new
    prefix, flight_nr, aircraft_ba_code, l.days_of_the_week, from, till, departure_iata, l.departure_time, arrival_iata, l.arrival_time = array
    l.flight_nr = prefix+flight_nr
    l.from = from.insert(-3,"20")
    l.till = till.insert(-3,"20")
    l.aircraft_type = AircraftType.find_or_create_by_ba_code(aircraft_ba_code)
    l.departure_airport = Airport.find_or_create_by_iata_code(departure_iata)
    l.arrival_airport = Airport.find_or_create_by_iata_code(arrival_iata)
    return l
  end
  
  # New version for anonymous data
  # Flt Desg,Eff Date,Dis Date,Freq,Dept Arp,Dept Time,Arvl Arp,Arrv Time,Subfleet,Service Type
  # SN 5129 ,1-sep-08,4-sep-08,12_4___,BRU,07:45,Dest14,09:00,SN  AR8,J
  def self.from_anon_array(array)
    l = FlightLegGroup.new
    flight_nr, l.from, l.till, l.days_of_the_week, departure_iata, l.departure_time, arrival_iata, l.arrival_time, aircraft_ba_code, blank = array
    l.flight_nr = flight_nr.gsub(' ','')
    l.aircraft_type = AircraftType.find_or_create_by_ba_code(aircraft_ba_code.gsub('SN  ',''))
    l.departure_airport = Airport.find_or_create_by_iata_code(departure_iata)
    l.arrival_airport = Airport.find_or_create_by_iata_code(arrival_iata)
    return l
  end
  
  # return the weekdays as an array of integers
  def weekdays
    @weekdays ||= days_of_the_week.gsub('_','').scan(/./).map(&:to_i)
  end
  
  def fly_on_date?(date)
    if date.between?(from,till)
      weekdays.include?(date.cwday)
    else
      return false
    end
  end
  
  # distance between departure airport and arrival airport
  def distance
    @distance ||= self.departure_airport.distance_from(self.arrival_airport,:units => :kms,:formula=>:sphere)
  end
  
  # return the departure_time in minutes from the start of the week
  # weekday should be cwday of a Date object (1 for monday, 7 for sunday)
  def departure_minutes(weekday)
    (weekday-1)*24*60 + self.departure_time.hour*60 + self.departure_time.min
  end
  
  # return the arrival in minutes from the start of the week
  def arrival_minutes(weekday)
    # add 24 hours when arrival is before departure
    (weekday-1)*24*60 + self.arrival_time.hour*60 + self.arrival_time.min + (self.departure_time < self.arrival_time ? 0 : 24*60)  
  end
  
  # return all dates this flight leg flies, between start_date and stop_date
  def dates(start_date=from,stop_date=till)
    # change start_date if from is later
    start_date = [from.to_date,start_date.to_date].max
    stop_date = [till.to_date,stop_date.to_date].min 
    dates = []
    start_date.upto(stop_date) do |date|
      dates << date if fly_on_date?(date)
    end
    return dates
  end
  
  def flight_legs(start_date=from,stop_date=till)
    self.dates(start_date,stop_date).collect { |date| FlightLeg.from_flg(self,date) }
  end
end
