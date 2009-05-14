require 'config.rb'
require 'activesupport'

sales_legs = SalesLeg.with_capacity(82).find(:all, :limit => 30)
dots_file = 'sales/dots.xml'

File.open(dots_file,'w') do |file|
  file.puts '<chart><graphs><graph gid="0">'
  sales_legs.each do |sl|
    start = sl.date - 119.days
    cross_date= sl.date - 4.weeks
    sold_at_cross_date = sl.sales_ticks.find_by_date(cross_date).seats_sold
    prev_seats_sold = 0
    start.upto(sl.date) do |date|
      day = (date-sl.date).to_i
      seats_sold = ((sl.sales_ticks.find_by_date(date).seats_sold / sold_at_cross_date.to_f)*100).round
      if prev_seats_sold != seats_sold
        file.puts "     <point x=\"#{day}\" y=\"#{seats_sold}\"/>"
        puts "#{day}\t#{seats_sold}"
        prev_seats_sold = seats_sold
      end
    end
  end
  file.puts '</graph></graphs></chart>'  
end