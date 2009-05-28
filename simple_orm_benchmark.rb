#!/usr/bin/env ruby
require 'rubygems'
require 'benchmark'
require 'yaml'
require 'optparse'

CONFIG_FILE = 'db.yml'
ORM_CONFIG = {}
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
  all_configs.sort.each{|c| system('ruby', __FILE__, *(options + [c]))}
  exit
elsif configs.length > 1
  options = ARGV - configs
  configs.each{|c| system('ruby', __FILE__, *(options + [c]))}
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
[lambda{"Model Object Creation: #{50*@n} objects"},
nil,
lambda{(50*@n).times{create_party}}],

[lambda{"Model Object Select: #{100*@n} objects #{@n} times"},
lambda{insert_party(100*@n)},
lambda{@n.times{all_parties}}],

[lambda{"Model Object Select and Save: #{50*@n} objects"},
lambda{insert_party(50*@n)},
lambda{save_all_parties}],

[lambda{"Model Object Destruction: #{100*@n} objects"},
lambda{insert_party(100*@n); @parties=all_parties},
lambda{destroy_parties(@parties)}],

[lambda{"Model Object And Associated Object Creation: #{20*@n} objects"},
nil,
lambda{(20*@n).times{create_party_with_person}}],

[lambda{"Model Object and Associated Object Destruction: #{25*@n} objects"},
lambda{insert_party_people(25*@n, 1)},
lambda{destroy_parties_and_people}],

[lambda{"Eager Loading Query Per Association With 1-1 Records: #{20*@n} objects #{@n*5/7} times"},
lambda{insert_party_people(20*@n, 1)},
lambda{(@n*5/7).times{eager_load_party_people}}],

[lambda{"Eager Loading Single Query With 1-1 Records: #{20*@n} objects #{@n*5/7} times"},
lambda{insert_party_people(20*@n, 1)},
lambda{(@n*5/7).times{eager_graph_party_people}}],

[lambda{"Eager Loading Query Per Association With 1-#{@n} Records: #{@n*@n} objects #{@n*5/7} times"},
lambda{insert_party_people(@n, @n)},
lambda{(@n*5/7).times{eager_load_party_people}}],

[lambda{"Eager Loading Single Query With 1-#{@n} Records: #{@n*@n} objects #{@n*5/7} times"},
lambda{insert_party_people(@n, @n)},
lambda{(@n*5/7).times{eager_graph_party_people}}],

[lambda{"Eager Loading Query Per Association With 1-#{@n}-#{@n} Records: #{2*@n*@n} objects #{@n*2/7} times"},
lambda{insert_party_both_people(@n, @n)},
lambda{(@n*2/7).times{eager_load_party_both_people}}],

[lambda{"Eager Loading Single Query With 1-#{@n}-#{@n} Records: #{2*@n*@n} objects 1 time"},
lambda{insert_party_both_people(@n, @n)},
lambda{eager_graph_party_both_people}],

[lambda{"Lazy Loading With 1-1 Records: #{20*@n} objects 1 time"},
lambda{insert_party_people(20*@n, 1)},
lambda{lazy_load_party_people}],

[lambda{"Lazy Loading With 1-#{@n} Records: #{@n*@n} objects #{@n/2} times"},
lambda{insert_party_people(@n, @n)},
lambda{(@n/2).times{lazy_load_party_people}}],

]

thread_block = lambda do
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

[lambda{"Light Threading with #{Math.sqrt(@n).round} threads"},
nil,
lambda{@num_threads=Math.sqrt(@n).round; instance_eval(&thread_block)}],

[lambda{"Heavy Threading with #{@n} threads"},
nil,
lambda{@num_threads=@n; instance_eval(&thread_block)}],

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
    l = lambda{instance_eval(&@bench)}
    @transaction ? transaction(&l) : l.call
    @mem_used = real_memory - start_mem

    GC.enable if $disable_gc
    GC.start
  end

  def all_parties
    Party.all
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
    return `ps -p #{Process::pid} -o rsz`.split("\n")[1].chomp.to_i
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
  Bench.new(true,b).bench
end

NO_TRANSACTION_BENCHES.each do |b|
  Bench.new(false,b).bench
end

Bench.drop_tables
