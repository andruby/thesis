require 'config'
require 'benchmark'

# puts Benchmark.measure {
#   @all_dates = FlightLeg.all.collect(&:dates)
# }


@all_dates.flatten!
puts "Total size = #{@all_dates.size}"