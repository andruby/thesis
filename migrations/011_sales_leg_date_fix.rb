class SalesLegDateFix < ActiveRecord::Migration
  def self.up
    rename_column :sales_legs, :date, :date_string
    add_column :sales_legs, :date, :date
    
    all = SalesLeg.all
    all.each do |sl|
      sl.date = Date.parse(sl.date_string)
      puts "#{sl.date_string} -> #{sl.date}"
      sl.save!
    end
    
    remove_column :sales_legs, :date_string
  end

  def self.down
    # not perfect
    remove_column :sales_legs, :date
    add_column :sales_legs, :date, :string  
  end
end