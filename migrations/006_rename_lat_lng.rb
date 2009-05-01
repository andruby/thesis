class RenameLatLng < ActiveRecord::Migration
  def self.up
    rename_column :airports, :longitude, :lng
    rename_column :airports, :latitude, :lat
  end

  def self.down
    rename_column :airports, :lat, :latitude
    rename_column :airports, :lng, :longitude
  end
end