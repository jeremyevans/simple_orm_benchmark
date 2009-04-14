require 'memory_gauge'
require 'performance_gauge'

puts "MEASURING SEQUEL'S EFFICIENCY:\n\n"
puts "How many parties do you want test with for each script?"
num_of_parties= gets.chomp.to_i
num_of_parties ||= 0

if num_of_parties == 0
  puts "The number of parties supplied was 0 . Tests not ran."
  return
end

puts "MEASURING CREATION OF #{num_of_parties} PARTIES\n\n"
  puts PerformanceGauge.benchmark_creating_n_objects( num_of_parties )
  puts "\n\n"
#
# *2 because bmbm runs create script twice
puts "MEASURING DESTRUCTION OF #{num_of_parties * 2} PARTIES"
  puts PerformanceGauge.benchmark_destroying_all_objects
  puts "\n\n"

puts "MEASURING CREATION OF #{num_of_parties} PARTIES AND #{num_of_parties} PEOPLE"
puts PerformanceGauge.creating_n_objects_with_a_person(num_of_parties)
puts "\n\n"

puts "MEASURING EAGER LOADING OF #{num_of_parties} PARTIES AND THEIR PEOPLE"
puts PerformanceGauge.loading_all_parties_with_their_people
puts "\n\n"

puts "Clear db to prep for additional execution of the script? [Y/N]"
a=gets.chomp
if a=="Y"
  puts "Clearing out db...."
  Party.destroy_all
  Person.destroy_all
end

puts "How many objects do you want to create for mem test?"
object_count=gets.chomp.to_i
object_count ||= 0
puts "MEASURING MEMORY ALLOCATION FOR INSTANTIATION #{object_count} PARTY OBJECTS"
kb_allocated, time_elapsed = MemoryGauge.measure_instantiation( object_count )
  puts "\t#{kb_allocated} KB allocated to instantiate #{object_count} PARTIES\n\n"
  puts "\tTime Elapsed: #{time_elapsed}"
