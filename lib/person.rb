require 'rubygems'
require 'mysql'
require 'sequel'

#Benchmark gem for profiling
Sequel.connect('mysql://root@localhost/sequel_party')
class Person < Sequel::Model  
  belongs_to :party
end