require 'sequel'
DB = Sequel.connect(YAML.load_file("db.yml"))

DB.create_table!(:parties) do
  primary_key :id
  String :theme
end

DB.create_table!(:people) do
  primary_key :id
  foreign_key :party_id, :parties
  String :name
  String :address
end

class Party < Sequel::Model
  one_to_many :people 
  
  def self.eager_load_people
    eager(:people).all.each{|party| party.people.size }
  end
end

class Person < Sequel::Model  
  many_to_one :party
end
