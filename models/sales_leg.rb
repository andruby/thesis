class SalesLeg < ActiveRecord::Base
  has_many :sales_ticks
  
  named_scope :with_capacity, lambda { |capacity|
        { :conditions => { :capacity => capacity } }
      }
  
  def self.from_array(array)
    l = SalesLeg.new
    l.date = array[1]
    destination = array[3]
    ports = array[4]
    l.flight_nr = array[5]
    l.flight_nr_date = l.flight_nr + '_' + l.date.day.to_s
    l.destination = destination.scan(/\d+/).first
    ports = ports.split
    l.departure_station = ports.first
    l.arrival_station = ports.last
    return l
  end
end
