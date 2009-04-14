require "lib/party"

class MemoryGauge
  class << self
    def real_memory
      return `ps -p #{Process::pid} -o rsz`.split("\n")[1].chomp.to_i
    end

    def instantiate_n_in_mem(in_mem_collection)
      in_mem_collection.each_index { |i| in_mem_collection[i]=Party.get(i)  }
    end

    def measure_instantiation(objects_to_instantiate=5000)
      # in_mem_collection= Array.new( objects_to_instantiate )
      mem_before_instantiation= real_memory
      start_time= Time.now

      parties= Party.all(:limit=> objects_to_instantiate )
      parties.each{|p| p.destroy }

      # instantiate_n_in_mem(in_mem_collection)
      # in_mem_collection.length

      end_time=Time.now
      time_elapsed= end_time - start_time

      mem_used= real_memory - mem_before_instantiation
      return mem_used, time_elapsed
    end
  end
end
