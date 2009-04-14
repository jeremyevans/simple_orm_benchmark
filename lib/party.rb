require "config/dependencies"

Sequel.connect('mysql://root@localhost/sequel_party')
class Party < Sequel::Model 
  has_many :people 
end