class CreateAircraftTypes < ActiveRecord::Migration
  def self.up
    create_table :aircraft_types do |t|
      t.string :iata_code
      t.string :ba_code
      t.string :name
      t.float :range
      t.float :fuel_burn
      t.integer :crew_requirement
      t.integer :passenger_capacity
    end
      
    add_index :aircraft_types, :ba_code, :unique => true  
  end

  def self.down
    drop_table :aircraft_types
  end
end