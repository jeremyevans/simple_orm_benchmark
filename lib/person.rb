require "config/dependencies"
require "config/db_connect"
Sequel.connect( DbConnect.new.connection_string )

class Person < Sequel::Model  
  belongs_to :party
end