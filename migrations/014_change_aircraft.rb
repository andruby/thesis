class ChangeAircraft < ActiveRecord::Migration
  def self.up
    remove_column :aircraft_types, :fuel_burn
    remove_column :aircraft_types, :speed
    remove_column :aircraft_types, :crew_requirement
    change_column :aircraft_types, :range, :string
    change_column :aircraft_types, :fixed_cost, :float
    change_column :aircraft_types, :var_cost, :float
  end

  def self.down
    add_column :aircraft_types, :speed, :integer
    add_column :aircraft_types, :fuel_burn, :float
    add_column :aircraft_types, :crew_requirement, :integer
    change_column :aircraft_types, :range, :integer
    change_column :aircraft_types, :fixed_cost, :integer
    change_column :aircraft_types, :var_cost, :integer
  end
end