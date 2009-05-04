class AddSalesTickCapacity < ActiveRecord::Migration
  def self.up
    add_column :sales_ticks, :capacity, :integer
  end

  def self.down
    remove_column :sales_ticks, :capacity
  end
end