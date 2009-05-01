require 'config.rb'

sales_data_file = '/Users/andrew/Desktop/thesis/data/sales.data'

# Demo line
# month	  Departure Date	rundt	      Droute	Dseg	        Dfltnb	  Physical  Capacity	sssam
# SEP08 	01SEP2008 	    05MAR2008 	Dest1 	BRU to Dest1 	SN 5401 	132 	    0

def parse_sales_data(txt_file)
  i=0
  File.open(txt_file,'r') do |file|
    while(line = file.gets)
      array = line.split(/[\s][\s]+/)
      flight_nr_date = "#{array[5]}_#{array[1][0..1]}"
      unless @sales_leg = SalesLeg.find_by_flight_nr_date(flight_nr_date)
        @sales_leg = SalesLeg.from_array(array)
        @sales_leg.save rescue PGError # when duplicate stop it from barking
      end
      @sales_leg.sales_ticks.create(:date => array[2],:seats_sold=>array[7])
      puts i if (i+=1) % 1000 == 0
    end
  end
end

parse_sales_data(sales_data_file)