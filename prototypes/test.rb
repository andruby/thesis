require 'config.rb'

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
  
  # haal de distributie voor gegeven input range
  def self.from_db(min_seat_sold,max_seat_sold)
    sql = 'select seats_sold(l.id,0) as "0d",count(*) from sales_legs l, sales_ticks t 
              where l.id = t.sales_leg_id and t.date = l.date - 28 and t.seats_sold 
              BETWEEN '+min_seat_sold.to_s+' and '+max_seat_sold.to_s+' group by "0d" order by "0d"'
    mc = MonteCarlo.new
    mc.possibility_array = SalesLeg.connection.select_all(sql).collect{ |t| [t["0d"].to_i,t["count"].to_i]}
    return mc
  end
end

# een groep met alle MonteCarlo generators voor alle begin waarden
class MonteCarloGroup
  attr_accessor :monte_carlos, :stap, :aantal
  
  # haal de probabiliteitsdistributie voor <aantal> groepen van <stap> 
  # en sla ze op in de @monte_carlos array
  def initialize(stap=5,aantal=34)
    @stap = stap
    @monte_carlos = []
    aantal.times do |x|
      van = x*stap
      tot = (x+1)*stap-1
      @monte_carlos[tot] = MonteCarlo.from_db(van,tot)
    end
  end
  
  def rnd_mc(verkochte_zetels_28d)
    # bereken de juiste mc index
    idx = (verkochte_zetels_28d / @stap.to_f).ceil*@stap-1
    @monte_carlos[idx].mc
  end
end

# Functies toevoegen aan Array
class Array 
  # bereken het gemiddelde
  def avg
    self.inject(:+) / self.size.to_f
  end
  
  # bereken de standaard deviatie
  def std_dev
    count = self.size
    mean = self.avg
    return Math.sqrt( self.inject(0) { |sum, e| sum + (e - mean) ** 2 } / count.to_f )
  end
end

puts "Distributies ophalen voor MonteCarlo"
@mc_group = MonteCarloGroup.new

test_nrs = []
10000.times { test_nrs << @mc_group.rnd_mc(41) }

filename = 'data/test_mc.txt'
File.open(filename, 'w') {|f| f.write(test_nrs.join("\n")) }
