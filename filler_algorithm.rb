require 'benchmark'

Benchmark.bm(10) do |bench|
  bench.report("Config:") do
    require 'config'
  end
  bench.report("Loading:") do
    @assignment = Assignment.new(load_from_yaml('data/flights_1_9.yml'))
  end
  bench.report("Schedule:") do
    @assignment.schedule!
  end
  bench.report("Winst:") do
    @results = @assignment.results
  end
end
p @results
