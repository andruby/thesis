class AddAirportHaul < ActiveRecord::Migration
  def self.up
    add_column :airports, :haul, :string
  end

  def self.down
    remove_column :airports, :haul
  end
end