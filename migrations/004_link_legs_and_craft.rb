class LinkLegsAndCraft < ActiveRecord::Migration
  def self.up
    add_column :flight_legs, :aircraft_type_id, :integer
    
    FlightLeg.all.each do |leg|
      leg.aircraft_type = AircraftType.find_or_create_by_ba_code(leg.aircraft_type)
      leg.save!
    end
    
    remove_column :flight_legs, :aircraft_type
  end

  def self.down
    add_column :flight_legs, :aircraft_type, :string    
    remove_column :flight_legs, :aircraft_type_id
  end
end