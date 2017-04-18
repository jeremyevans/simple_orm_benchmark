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

Row = Struct.new(*INPUT_COLUMNS.keys)

rows         = ARGF.read.split("\n").map { |line| Row.new *line.split(",") }
config_names = rows.map(&:config_name).uniq
benchmarks   = {}

rows.each do |row|
  key = "#{row.bench_name} (#{row.transaction_used})"

  b = benchmarks[key] ||= {}
  b[row.config_name] = row
end

puts "Benchmark,#{config_names.join(',')}"

benchmarks.sort.each do |bench_name, results|
  cells = config_names.map do |config_name|
    if row = results[config_name]
      row.elapsed_real_time.to_f.round(4)
    end
  end

  cells.unshift(bench_name)
  puts cells.join(',')
end
