class Airport < ActiveRecord::Base
  has_many :flight_leg_groups_in, :class_name => "FlightLegGroup", :foreign_key => "arrival_airport_id"
  has_many :flight_leg_groups_out, :class_name => "FlightLegGroup", :foreign_key => "departure_airport_id"
  validates_uniqueness_of :iata_code
  # Stop getting additional data: tis fictieve data
  #before_create :get_aditional_data
  # acts_as_mappable :default_units => :kms, 
  #                  :default_formula => :sphere, 
  #                  :distance_field_name => :distance 
  
  def get_aditional_data
    require 'hpricot'
    require 'open-uri'
    doc = Hpricot(open("http://gc.kls2.com/airport/#{iata_code}","User-Agent" => "Ruby"))
    self.lat = doc.at("abbr.latitude")['title'].to_f
    self.lng = doc.at("abbr.longitude")['title'].to_f
    self.city = doc.at("span.locality").inner_html
    self.country = doc.at("span.country-name").inner_html
    self.name = doc.at("td.fn").inner_html.gsub(/<[^>]+>/,'')
  end
  
  def self.order_by_distance_from_bru
    bru = self.find_by_iata_code('BRU')
    self.find(:all,:origin => bru,:order => 'distance')
  end
  
  def in_uit_balans(start_date,end_date)
    in_count = 0 
    self.flight_leg_groups_in.each { |flg| 
      in_count += flg.dates(start_date,end_date).size
    }
    out_count = 0 
    self.flight_leg_groups_out.each { |flg| 
      out_count += flg.dates(start_date,end_date).size
    }
    diff = (in_count-out_count).abs
    puts "(#{diff}) #{self.iata_code}: IN=#{in_count} OUT=#{out_count}" unless in_count == out_count
    #raise "Count klopt niet voor #{self.iata_code}: IN=#{in_count} OUT=#{out_count}" unless in_count == out_count
    return diff
  end
  
  def planes
    counters = {}
    self.flight_leg_groups_in.collect(&:aircraft_type).each { |a| counters[a.ba_code] = (counters[a.ba_code] || 0) + 1 }
    p counters
  end
end