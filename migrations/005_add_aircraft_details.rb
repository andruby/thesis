class AddAircraftDetails < ActiveRecord::Migration
  def self.up
    add_column :aircraft_types, :count, :integer
    add_column :aircraft_types, :speed, :integer
    change_column :aircraft_types, :range, :integer
  end

  def self.down
    change_column :aircraft_types, :range, :float
    remove_column :aircraft_types, :speed
    remove_column :aircraft_types, :count
  end
end