require 'config'

class MonteCarlo
  attr_accessor :possibility_distribution
  # geef random een waarde uit de array van mogelijkheden
  def mc
    rnd = rand(total_count)
    @possibility_distribution.detect{ |pos| (rnd -= pos.last) <= 0 }.first
  end
  
  # tel het totaal aantal 'frequencies'
  def total_count
    @total_count ||= @possibility_distribution.inject(0) { |sum, n| sum + n.last }
  end
  
  # haal de kansverdeling uit de database voor gegeven input range
  def self.from_db(min_seat_sold,max_seat_sold)
    sql = 'select seats_sold(l.id,0) as "0d",count(*) from sales_legs l, sales_ticks t 
              where l.id = t.sales_leg_id and t.date = l.date - 28 and t.seats_sold 
              BETWEEN '+min_seat_sold.to_s+' and '+max_seat_sold.to_s+' group by "0d" order by "0d"'
    mc = MonteCarlo.new
    mc.possibility_distribution = SalesLeg.connection.select_all(sql).collect{ |t| [t["0d"].to_i,t["count"].to_i]}
    return mc
  end
end

# MonteCarloGroup is een object die alle MonteCarlo generators voor elke input range bijhoud
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

# Functies toevoegen aan Array's
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

# functie die de procentuele kostenreductie berekent
def gain(new_total_cost,original_total_cost = @original_total_cost)
  ((original_total_cost - new_total_cost) / original_total_cost.to_f) * 100
end

# flights inladen
session_name = '7_27_conf7'
AssignmentParameters.from_ilog('config_7')
flights = load_from_yaml("data/assignments/#{session_name}_cplex.yml")
@assignment = Assignment.new(flights)

# toon de originele results
print "original results: "
original_result = @assignment.results(true)
puts @original_total_cost = original_result[:total_cost]

print "assigned results: "
assigned_result = @assignment.results
puts assigned_total_cost = assigned_result[:total_cost]

print "original gain: "
puts gain(assigned_total_cost)

#####################
# do the montecarlo #
#####################

numbers = []
10000.times do |counter|
  flights.each do |f| 
    # MonteCarlo Randomized het werkelijk aantal passagiers van elke vlucht
    f.pax_1 = @mc_group.rnd_mc(f.pax_1_28d)
    f.pax_2 = @mc_group.rnd_mc(f.pax_2_28d)
  end
  @assignment.flights = flights
  numbers << gain(@assignment.results[:total_cost],@assignment.results(true)[:total_cost])
  puts "#{counter}" if counter % 500 == 0 # progress indicatie
end

# Toon basic statistieken
puts "Minimum: #{numbers.min}"
puts "Maximum: #{numbers.max}"
puts "Average: #{numbers.avg}"
puts "StdDev: #{numbers.std_dev}"

# Schrijf alle nummers naar een textfile (voor de grafieken)
nr_file = 'data/montecarlo/montecarlo_results_2_d7.txt'
puts "writing the numbers to #{nr_file}"
File.open(nr_file, 'w') {|f| f.write(numbers.join("\n")) }
puts "done"
