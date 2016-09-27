#!/usr/bin/env ruby
results = {}
adapters = []
ARGF.read.split("\n").each do |l|
  row = l.split(",")
  bench = row[2]
  trans = row[-1]
  adapter = row[0]
  adapters << adapter
  (results["#{bench}-#{trans}"] ||= {})[adapter] = row
end

adapters = adapters.uniq.sort
puts "Benchmark,#{adapters.join(',')}"
results.sort.each do |k,v|
  puts "#{k},#{adapters.map do |a|
    next unless v[a]
    v[a][6]
  end.join(',')}"
end
