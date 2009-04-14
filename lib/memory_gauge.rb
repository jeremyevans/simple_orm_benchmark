class MemoryGauge
  def self.measure(objects_to_instantiate)
    GC.start
    GC.disable
    mem_before_instantiation= real_memory
    start_time= Time.now

    parties = Party.all
    parties.each do |p|
      p.people.each{|person| person.destroy}
      p.destroy
    end

    end_time=Time.now
    time_elapsed= end_time - start_time

    mem_used= real_memory - mem_before_instantiation
    GC.enable
    GC.start
    return mem_used, time_elapsed
  end

  def self.real_memory
    return `ps -p #{Process::pid} -o rsz`.split("\n")[1].chomp.to_i
  end
  private_class_method :real_memory
end
