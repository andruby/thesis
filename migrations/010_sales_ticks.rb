class SalesTicks < ActiveRecord::Migration
  def self.up
    create_table :sales_ticks do |t|
      t.integer :sales_leg_id
      t.date :date
      t.integer :seats_sold
    end
  end

  def self.down
    drop_table :sales_ticks
  end
end