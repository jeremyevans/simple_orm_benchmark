#!/usr/bin/env ruby

INPUT_COLUMNS = {
  config_name:       "Name of configuration",
  level:             "Testing level",
  bench_name:        "Name of benchmark",
  user_cpu_time:     "Amount of user CPU time",
  system_cpu_time:   "Amount of system CPU time",
  total_cpu_time:    "Amount of total CPU time",
  elapsed_real_time: "Amount of actual/real/wallclock time",
  kb_of_memory_used: "Difference in process memory usage from the benchmark",
  transaction_used:  "Whether a transaction was used",
}

#
# NOTE: 'benchmarks' are stored as a hash of hashes
#
# eg:
#
# {
#   "Some Benchmark" => {
#     "sequel-postgresql" => #<Row...>,
#     "sequel-mysql"      => #<Row...>,
#     ...
#   },
#   "Another benchmark" => {
#     ...
#   },
#   ...
# }
#

Row = Struct.new *INPUT_COLUMNS.keys

rows         = ARGF.read.split("\n").map { |line| Row.new *line.split(",") }
config_names = rows.map(&:config_name).uniq
benchmarks   = {}

rows.each do |row|
  key = "#{row.bench_name} (#{row.transaction_used})"

  benchmarks[key] ||= {}
  benchmarks[key][row.config_name] = row
end

config_names = config_names.to_a

puts "#{config_names.join(',')},Benchmark"

benchmarks.each do |bench_name, results|

  fastest, _ = results.min_by { |config_name, row| row.elapsed_real_time.to_f }

  cells = config_names.map do |config_name|
    if row = results[config_name]
      "#{row.elapsed_real_time.to_f.round(4)}#{"*" if fastest == config_name} (#{row.kb_of_memory_used}k)"
    end
  end

  puts "#{cells.join(',')},#{bench_name}"
end
