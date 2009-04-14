require "config/dependencies"
require "config/db_connect"
Sequel.connect( DbConnect.new.connection_string )

class Party < Sequel::Model 
  has_many :people 
end