class SalesLeg < ActiveRecord::Base
  has_many :sales_ticks
  
  named_scope :with_capacity, lambda { |capacity|
        { :conditions => { :capacity => capacity } }
      }
  
  def self.from_array(array)
    l = SalesLeg.new
    blank, l.date, blank, destination, ports, l.flight_nr, l.capacity, blank  = array
    l.flight_nr_date = "#{l.flight_nr}_#{l.date[0..1]}"
    l.destination = destination.scan(/\d+/).first
    ports = ports.split
    l.departure_station = ports.first
    l.arrival_station = ports.last
    return l
  end
end
