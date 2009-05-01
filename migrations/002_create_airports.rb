class CreateAirports < ActiveRecord::Migration
  def self.up
    create_table :airports do |t|
      t.string :iata_code
      t.string :name
      t.string :city
      t.string :country
      t.float :latitude
      t.float :longitude
    end
    
    add_index :airports, :iata_code, :unique => true
    
    add_column :flight_legs, :departure_airport_id, :integer
    add_column :flight_legs, :arrival_airport_id, :integer
    remove_column :flight_legs, :arrival_station
    remove_column :flight_legs, :departure_station
  end

  def self.down
    add_column :flight_legs, :arrival_station, :string
    add_column :flight_legs, :departure_station, :string
    remove_column :flight_legs, :arrival_airport_id
    remove_column :flight_legs, :departure_airport_id
    drop_table :airports
  end
end