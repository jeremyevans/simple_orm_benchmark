require File.join(File.dirname(__FILE__), "..", "performance_gauge")

describe PerformanceGauge do
  it "should print a benchmark for creating n parties" do
    PerformanceGauge.benchmark_creating_n_objects(1000)
  end

  it "should print a benchmark for destroying all parties" do
    PerformanceGauge.benchmark_destroying_all_objects
  end
end
