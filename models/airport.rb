class Airport < ActiveRecord::Base
  has_many :flight_leg_groups_in, :class_name => "FlightLegGroup", :foreign_key => "arrival_airport_id"
  has_many :flight_leg_groups_out, :class_name => "FlightLegGroup", :foreign_key => "departure_airport_id"
  validates_uniqueness_of :iata_code
  # Stop getting additional data: tis fictieve data
  #before_create :get_aditional_data
  acts_as_mappable :default_units => :kms, 
                   :default_formula => :sphere, 
                   :distance_field_name => :distance 
  
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
end