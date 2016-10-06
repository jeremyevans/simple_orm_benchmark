#!/usr/bin/env ruby
require 'rubygems'
require 'benchmark'
require 'yaml'
require 'optparse'
require 'rbconfig'
$: << '.'

CONFIG_FILE = 'db.yml'
ORM_CONFIG = {}
RUBY=ENV['RUBY'] || File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
config = nil
$level = 5
$disable_gc = false
$all_configs = false

def parse_config(v)
  unless config = (YAML.load(File.read(CONFIG_FILE))[v] rescue nil)
    puts "ERROR: Unable to load config #{v} from #{CONFIG_FILE}!"
    exit(1)
  end
  orm = config.delete('orm')
  ORM_CONFIG.merge!(config)
  orm
end

def all_configs
  YAML.load(File.read(CONFIG_FILE)).keys rescue []
end

opts = OptionParser.new do |opts|
  opts.banner = "Ruby ORM Simple Benchmark Tool"
  opts.define_head "Usage: simple_orm_benchmarker [options] CONFIG"
  opts.separator ""
  opts.separator "CONFIG is the entry in db.yml to use (e.g. sequel-postgresql)"
  opts.separator ""
  
  opts.on("-a", "--all-configs", "Test all configurations") do
    $all_configs = true
  end
  
  opts.on("-g", "--disable-gc", "Disable GC during the tests") do
    $disable_gc = true
  end
  
  opts.on("-l", "--level LEVEL", "Testing level") do |l|
    $level = l.to_i
  end
end
configs = opts.permute(*ARGV)
if $all_configs
  options = ARGV - ["-a"] - configs
  all_configs.sort.each{|c| system(RUBY, __FILE__, *(options + [c]))}
  exit
elsif configs.length > 1
  options = ARGV - configs
  configs.each{|c| system(RUBY, __FILE__, *(options + [c]))}
  exit
end
opts.parse!

if ARGV.length == 0
  puts "ERROR: No configuration specified!\n"
  puts opts
  exit(1)
end
$config = ARGV.shift

require "models/#{parse_config($config)}"

BENCHES=[
[proc{"Model Object Creation: #{50*@n} objects"},
nil,
proc{(50*@n).times{create_party}}],

[proc{"Model Object Select: #{100*@n} objects #{@n} times"},
proc{insert_party(100*@n)},
proc{@n.times{all_parties}}],

[proc{"Model Object Select PK: #{10*@n} objects #{@n} times"},
proc{insert_party(10*@n); @party_ids=all_parties.map{|p| p.id}},
proc{@n.times{@party_ids.each{|i| get_party(i)}}}],

[proc{"Model Object Select Hash: #{10*@n} objects #{@n} times"},
proc{insert_party(10*@n); @party_ids=all_parties.map{|p| p.id}},
proc{@n.times{@party_ids.each{|i| get_party_hash(i)}}}],

[proc{"Model Object Select and Save: #{50*@n} objects"},
proc{insert_party(50*@n)},
proc{save_all_parties}],

[proc{"Model Object Destruction: #{100*@n} objects"},
proc{insert_party(100*@n); @parties=all_parties},
proc{destroy_parties(@parties)}],

[proc{"Model Object And Associated Object Creation: #{20*@n} objects"},
nil,
proc{(20*@n).times{create_party_with_person}}],

[proc{"Model Object and Associated Object Destruction: #{25*@n} objects"},
proc{insert_party_people(25*@n, 1)},
proc{destroy_parties_and_people}],

[proc{"Eager Loading Query Per Association With 1-1 Records: #{20*@n} objects #{@n*5/7} times"},
proc{insert_party_people(20*@n, 1)},
proc{(@n*5/7).times{eager_load_party_people}}],

[proc{"Eager Loading Single Query With 1-1 Records: #{20*@n} objects #{@n*5/7} times"},
proc{insert_party_people(20*@n, 1)},
proc{(@n*5/7).times{eager_graph_party_people}}],

[proc{"Eager Loading Query Per Association With 1-#{@n} Records: #{@n*@n} objects #{@n*5/7} times"},
proc{insert_party_people(@n, @n)},
proc{(@n*5/7).times{eager_load_party_people}}],

[proc{"Eager Loading Single Query With 1-#{@n} Records: #{@n*@n} objects #{@n*5/7} times"},
proc{insert_party_people(@n, @n)},
proc{(@n*5/7).times{eager_graph_party_people}}],

[proc{"Eager Loading Query Per Association With 1-#{@n}-#{@n} Records: #{2*@n*@n} objects #{@n*2/7} times"},
proc{insert_party_both_people(@n, @n)},
proc{(@n*2/7).times{eager_load_party_both_people}}],

[proc{"Eager Loading Single Query With 1-#{@n}-#{@n} Records: #{2*@n*@n} objects 1 time"},
proc{insert_party_both_people(@n, @n)},
proc{eager_graph_party_both_people}],

[proc{"Lazy Loading With 1-1 Records: #{20*@n} objects 1 time"},
proc{insert_party_people(20*@n, 1)},
proc{lazy_load_party_people}],

[proc{"Lazy Loading With 1-#{@n} Records: #{@n*@n} objects #{@n/2} times"},
proc{insert_party_people(@n, @n)},
proc{(@n/2).times{lazy_load_party_people}}],

]

thread_block = proc do
  threads = []
  @num_threads.round.times do
    threads << Thread.new do
      with_connection do
        insert_party(@n)
        @n.times do
          p = first_party
          update_party(p, 'Christmas')
          destroy_parties([p])
        end
      end
    end
    threads.each{|t| t.join}
  end
end

NO_TRANSACTION_BENCHES = 
[

[proc{"Light Threading with #{Math.sqrt(@n).round} threads"},
nil,
proc{@num_threads=Math.sqrt(@n).round; instance_eval(&thread_block)}],

[proc{"Heavy Threading with #{@n} threads"},
nil,
proc{@num_threads=@n; instance_eval(&thread_block)}],

]

JSON_BENCHES = [
  [proc{"Model Object Select JSON Nested: #{10*@n} objects #{@n} times"},
   proc{insert_party_deep(10*@n); @party_ids=all_parties.map{|p| p.id}},
   proc{@n.times{@party_ids.each{|i| get_party_hash_deep}}}],

  [proc{"Model Object Update JSON Nested: #{10*@n} objects #{@n} times"},
   proc{insert_party_deep(10*@n); @party_ids=all_parties.map{|p| p.id}},
   proc{@n.times{@party_ids.each{|i| update_party_hash_deep(i)}}}],

  [proc{"Model Object Update JSON: #{10*@n} objects #{@n} times"},
   proc{insert_party_deep(10*@n); @party_ids=all_parties.map{|p| p.id}},
   proc{@n.times{@party_ids.each{|i| update_party_hash_full(i)}}}],
]

class Bench
  def initialize(transaction, bench_array)
    @n = 2**$level
    @transaction = transaction
    @label, @before, @bench = bench_array
  end
  
  def bench
    begin
      instance_eval(&@before) if @before
      res = "#{$config},Level #{$level},#{Benchmark.measure(instance_eval(&@label)){_bench}.format('%n,%u,%y,%t,%r').gsub(/[()]/, '')}"
    ensure
      delete_all
    end
    puts "#{res},#{@mem_used},#{'No ' unless @transaction}Transaction"
    $stdout.flush
  end

  private

  def _bench
    GC.start
    GC.disable if $disable_gc

    start_mem = real_memory
    l = proc{instance_eval(&@bench)}
    @transaction ? transaction(&l) : l.call
    @mem_used = real_memory - start_mem

    GC.enable if $disable_gc
    GC.start
  end

  def create_party
    Party.create(:theme=>"Halloween")
  end

  def create_party_with_person
    party = Party.create(:theme=>"X-mas")
    Person.create(:party=>party, :name=>"Test_#{party.id}")
  end

  def destroy_parties(parties)
    parties.each{|p| p.destroy}
  end
  
  def destroy_parties_and_people
    all_parties.each do |p|
      p.people.each{|person| person.destroy}
      p.destroy
    end
  end

  def lazy_load_party_people
    all_parties.each{|p| p.people.each{|p| p.id}}
  end
  
  def real_memory
    return `ps -p #{Process::pid} -o rss`.split("\n")[1].chomp.to_i
  end
  
  def save_all_parties
    all_parties.each{|p| p.theme += '1'; p.save}
  end
  
  def update_party(party, theme)
    party.theme = theme
    party.save
  end
end

BENCHES.each do |b|
  Bench.new(false,b).bench
  Bench.new(true,b).bench unless ORM_CONFIG['transactional'] === false
end

NO_TRANSACTION_BENCHES.each do |b|
  Bench.new(false,b).bench
end

if JSON_SUPPORTED
  JSON_BENCHES.each do |b|
    Bench.new(false,b).bench
    Bench.new(true,b).bench unless ORM_CONFIG['transactional'] === false
  end
end

Bench.drop_tables
