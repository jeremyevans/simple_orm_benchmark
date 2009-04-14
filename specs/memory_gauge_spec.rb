require File.join(File.dirname(__FILE__), "..", "memory_gauge")

describe MemoryGauge do
  it "should return an integer representing the memory currently in use" do
    MemoryGauge.real_memory.should be_an_instance_of(Fixnum)
  end

  it "should gauge the memory used to create each party for each party" do
    objects_to_instantiate= 10000
    kb_allocated= MemoryGauge.measure_instantiation( objects_to_instantiate )
    p "<strong>#{kb_allocated} KB</strong> allocated to instantiate <strong>#{objects_to_instantiate}</strong> parties" 
    MemoryGauge.measure_instantiation.should be_an_instance_of(Fixnum)
  end
end
