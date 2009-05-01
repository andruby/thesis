class CreateFlightLegs < ActiveRecord::Migration
  def self.up
    create_table :flight_legs do |t|
      t.string :flight_nr
      t.string :aircraft_type
      t.string :days_of_the_week
      t.date :from
      t.date :till
      t.string :departure_station 
      t.time :departure_time
      t.string :arrival_station 
      t.time :arrival_time
    end
  end

  def self.down
    drop_table :flight_legs
  end
end