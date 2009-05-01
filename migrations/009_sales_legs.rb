class SalesLegs < ActiveRecord::Migration
  def self.up
    create_table :sales_legs do |t|
      t.string :flight_nr
      t.string :flight_nr_date
      t.string :date
      t.integer :destination
      t.string :departure_station 
      t.string :arrival_station 
      t.integer :capacity
    end
    
    add_index :sales_legs, :flight_nr_date, :unique => true
  end

  def self.down
    drop_table :sales_legs
  end
end