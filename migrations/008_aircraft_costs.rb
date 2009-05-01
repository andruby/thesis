class AircraftCosts < ActiveRecord::Migration
  def self.up
    add_column :aircraft_types, :fixed_cost, :integer
    add_column :aircraft_types, :var_cost, :integer
  end

  def self.down
    remove_column :aircraft_types, :fixed_cost
    remove_column :aircraft_types, :var_cost
  end
end