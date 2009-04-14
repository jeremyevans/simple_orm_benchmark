#!/usr/bin/env ruby
require 'rubygems'
require 'benchmark'
require 'yaml'
require 'optparse'

require 'performance_gauge'
require 'memory_gauge'

orm = 'sequel'
number = 1000

opts = OptionParser.new do |opts|
  opts.banner = "Ruby ORM Simple Benchmark Tool"
  
  opts.on("-o", "--orm ORM", "the ORM to use (sequel, active_record)") do |v|
    orm = v
  end
  
  opts.on("-n", "--number NUMBER", "Number of objects to test with") do |v|
    number = v.to_i
  end
end
opts.parse!

require "models/#{orm}"

puts "MEASURING #{orm}:\n\n"

if number == 0
  puts "The number of parties supplied was 0 . Tests not ran."
  return
end

puts "MEASURING CREATION OF #{number} PARTIES"
puts PerformanceGauge.benchmark_creating_n_objects( number )

# *2 because bmbm runs create script twice
puts "\nMEASURING DESTRUCTION OF #{number * 2} PARTIES"
puts PerformanceGauge.benchmark_destroying_all_objects

puts "\nMEASURING CREATION OF #{number} PARTIES AND #{number} PEOPLE"
puts PerformanceGauge.creating_n_objects_with_a_person(number)

puts "\nMEASURING EAGER LOADING OF #{number} PARTIES AND THEIR PEOPLE"
puts PerformanceGauge.loading_all_parties_with_their_people

puts "\nMEASURING MEMORY ALLOCATION FOR INSTANTIATION #{number} PARTY OBJECTS"
kb_allocated, time_elapsed = MemoryGauge.measure( number )
puts "\t#{kb_allocated} KB allocated to instantiate #{number} PARTIES\n\n"
puts "\tTime Elapsed: #{time_elapsed}"

Party.drop_tables
