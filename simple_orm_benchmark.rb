#!/usr/bin/env ruby
require 'rubygems'
require 'benchmark'
require 'yaml'
require 'optparse'

require 'lib/performance_gauge'
require 'lib/memory_gauge'

CONFIG_FILE = 'db.yml'
ORM_CONFIG = {}
config = nil
orm = 'sequel'
number = 1000

def parse_config(v)
  unless config = (YAML.load(File.read(CONFIG_FILE))[v] rescue nil)
    puts "ERROR: Unable to load config #{v} from #{CONFIG_FILE}!"
    exit(1)
  end
  orm = config.delete('orm')
  ORM_CONFIG.merge!(config)
  orm
end

opts = OptionParser.new do |opts|
  opts.banner = "Ruby ORM Simple Benchmark Tool"
  opts.define_head "Usage: simple_orm_benchmarker [options] CONFIG"
  opts.separator ""
  opts.separator "CONFIG is the entry in db.yml to use (e.g. sequel-postgresql)"
  opts.separator ""
  
  opts.on("-n", "--number NUMBER", "Number of objects to test with") do |v|
    number = v.to_i
  end
end
opts.parse!

unless config = ARGV.shift
  puts "ERROR: No configuration specified!\n"
  puts opts
  exit(1)
end
orm = parse_config(config)

require "models/#{orm}"

puts "MEASURING #{orm} using config #{config}:\n\n"

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
