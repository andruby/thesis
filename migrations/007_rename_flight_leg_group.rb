class RenameFlightLegGroup < ActiveRecord::Migration
  def self.up
    rename_table :flight_legs, :flight_leg_groups
  end

  def self.down
    rename_table :flight_leg_groups, :flight_legs
  end
end