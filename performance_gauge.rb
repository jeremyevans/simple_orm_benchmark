require "lib/party"
require "lib/person"
require 'benchmark'

class PerformanceGauge
  class << self
    def creating_n_objects_with_a_person(parties_to_create)
      Benchmark.bmbm do |x|
        x.report("") do
          parties_to_create.times do
            party= Party.create( {:theme=>"X-mas"} )
            Person.create(:party=>party, :name=>"Test_#{party.id}")
          end
        end
      end
    end
    
    def loading_all_parties_with_their_people
      Benchmark.bmbm do |x| 
        x.report("") do
         parties= Party.eager(:people).all 
         parties.each {|party| people= party.people; people.size }
       end
      end
    end

    def benchmark_creating_n_objects(objects_to_create=1000)
      Benchmark.bmbm do |x|
        x.report("") do
          create_n_parties(objects_to_create)
        end
      end
    end

    def benchmark_destroying_all_objects()
      create_n_parties(1000) if Party.count == 0
      parties= Party.all
      Benchmark.bm do |x|
        x.report("") do
          parties.each {|party| party.destroy }
        end
      end
    end
  end

  private
  def self.create_n_parties(parties_to_create)
    parties_to_create.times { p=Party.create({:theme=>"Halloween"}) }
  end
end
