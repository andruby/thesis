require 'config'

class MonteCarlo
  attr_accessor :possibility_array
  # geef random een waarde uit de array van mogelijkheden
  def mc
    rnd = rand(total_count)
    @possibility_array.detect{ |pos| (rnd -= pos.last) <= 0 }.first
  end
  
  # tel het totaal aantal 'frequencies'
  def total_count
    @total_count ||= @possibility_array.inject(0) { |sum, n| sum + n.last }
  end
  
  def self.from_db(min_seat_sold,max_seat_sold)
    sql = 'select seats_sold(l.id,0) as "0d",count(*) from sales_legs l, sales_ticks t 
              where l.id = t.sales_leg_id and t.date = l.date - 28 and t.seats_sold 
              BETWEEN '+min_seat_sold.to_s+' and '+max_seat_sold.to_s+' group by "0d" order by "0d"'
    mc = MonteCarlo.new
    mc.possibility_array = SalesLeg.connection.select_all(sql).collect{ |t| [t["0d"].to_i,t["count"].to_i]}
    return mc
  end
end

mc_20 = MonteCarlo.from_db(0,20)
mc_40 = MonteCarlo.from_db(21,40)
mc_60 = MonteCarlo.from_db(41,60)

puts "MC20"
10.times {
  puts mc_20.mc
}
puts "MC40"
10.times {
  puts mc_40.mc
}
puts "MC60"
10.times {
  puts mc_40.mc
}