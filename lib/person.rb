require "config/dependencies"

Sequel.connect('mysql://root@localhost/sequel_party')

class Person < Sequel::Model  
  belongs_to :party
end