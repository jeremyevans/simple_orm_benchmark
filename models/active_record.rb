require 'active_record'
ActiveRecord::Base.establish_connection(ORM_CONFIG)
c = ActiveRecord::Base.connection
c.drop_table(:people) rescue nil
c.drop_table(:parties) rescue nil

c.create_table(:parties) do |t|
  t.string :theme
end

c.create_table(:people) do |t|
  t.integer :party_id
  t.integer :other_party_id
  t.string :name
  t.string :address
end

class Party < ActiveRecord::Base
  has_many :people
  has_many :other_people, :class_name=>'Person', :foreign_key=>'other_party_id'
end

class Person < ActiveRecord::Base  
  belongs_to :party
  belongs_to :other_party, :class_name=>'Party', :foreign_key=>'other_party_id'
end

class Bench
  def delete_all
    c = ActiveRecord::Base.connection
    c.execute("DELETE FROM people")
    c.execute("DELETE FROM parties")
  end

  def all_parties
    Party.all.to_a
  end

  def get_party(id)
    Party.find(id)
  end

  def get_party_hash(id)
    Party.find_by(:id=>id)
  end

  def eager_graph_party_both_people
    Party.eager_load(:people, :other_people).where('people.id=people.id AND other_people_parties.id=other_people_parties.id').to_a.each{|party| party.people.each{|p| p.id}; party.other_people.each{|p| p.id}}
  end

  def eager_graph_party_people
    Party.eager_load(:people).where('people.id=people.id').to_a.each{|party| party.people.each{|p| p.id}}
  end

  def eager_load_party_both_people
    Party.preload(:people, :other_people).to_a.each{|party| party.people.each{|p| p.id}; party.other_people.each{|p| p.id}}
  end

  def eager_load_party_people
    Party.preload(:people).to_a.each{|party| party.people.each{|p| p.id}}
  end
  
  def first_party
    Party.first
  end

  def insert_party(times)
    c = ActiveRecord::Base.connection
    times.times{c.execute("INSERT INTO parties (theme) VALUES ('Halloween')")}
  end

  def insert_party_people(times, people_per_party)
    c = ActiveRecord::Base.connection
    times.times do
      p = Party.create(:theme=>'Halloween')
      people_per_party.times{c.execute("INSERT INTO people (name, party_id) VALUES ('Party_#{p.id}', #{p.id})")}
    end
  end

  def insert_party_both_people(times, people_per_party)
    c = ActiveRecord::Base.connection
    times.times do
      p = Party.create(:theme=>'Halloween')
      people_per_party.times do
        c.execute("INSERT INTO people (name, party_id) VALUES ('Party_#{p.id}', #{p.id})")
        c.execute("INSERT INTO people (name, other_party_id) VALUES ('Party_#{p.id}', #{p.id})")
     end
    end
  end

  def transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end
  
  def with_connection
    yield
    ActiveRecord::Base.clear_active_connections!
  end

  def self.drop_tables
    c = ActiveRecord::Base.connection
    c.drop_table(:people)
    c.drop_table(:parties)
  end
end
