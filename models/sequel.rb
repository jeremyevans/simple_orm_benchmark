require 'sequel'
DB = Sequel.connect(ORM_CONFIG)
DB.drop_table(:people) rescue nil
DB.drop_table(:parties) rescue nil

DB.create_table(:parties) do
  primary_key :id
  String :theme
end

DB.create_table(:people) do
  primary_key :id
  foreign_key :party_id, :parties
  foreign_key :other_party_id, :parties
  String :name
  String :address
end

class Party < Sequel::Model
  one_to_many :people 
  one_to_many :other_people, :class=>:Person, :key=>:other_party_id
end

class Person < Sequel::Model  
  many_to_one :party
  many_to_one :other_party, :class=>:Party
end

class Bench
  def delete_all
    DB << "DELETE FROM people"
    DB << "DELETE FROM parties"
  end

  def eager_graph_party_both_people
    Party.filter('people.id = people.id AND other_people.id=other_people.id').eager_graph(:people, :other_people).all{|party| party.people.each{|p| p.id}; party.other_people.each{|p| p.id}}
  end

  def eager_graph_party_people
    Party.filter('people.id = people.id').eager_graph(:people).all{|party| party.people.each{|p| p.id}}
  end

  def eager_load_party_both_people
    Party.eager(:people, :other_people).all{|party| party.people.size; party.other_people.each{|p| p.id}}
  end

  def eager_load_party_people
    Party.eager(:people).all{|party| party.people.each{|p| p.id}}
  end

  def insert_party(times)
    times.times{DB << "INSERT INTO parties (theme) VALUES ('Halloween')"}
  end

  def insert_party_people(times, people_per_party)
    times.times do
      p = Party.create(:theme=>'Halloween')
      people_per_party.times{DB << "INSERT INTO people (name, party_id) VALUES ('Party_#{p.id}', #{p.id})"}
    end
  end

  def insert_party_both_people(times, people_per_party)
    times.times do
      p = Party.create(:theme=>'Halloween')
      people_per_party.times do 
        DB << "INSERT INTO people (name, party_id) VALUES ('Party_#{p.id}', #{p.id})"
        DB << "INSERT INTO people (name, other_party_id) VALUES ('Party_#{p.id}', #{p.id})"
      end
    end
  end

  def transaction(&block)
    DB.transaction(&block)
  end

  def self.drop_tables
    DB.drop_table(:people, :parties)
  end
end
