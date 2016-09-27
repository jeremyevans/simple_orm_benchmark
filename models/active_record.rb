require 'active_record'
if ORM_CONFIG['debug']
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = :debug
end
ActiveRecord::Base.establish_connection(ORM_CONFIG)
DB = ActiveRecord::Base.connection
DB.drop_table(:people) rescue nil
DB.drop_table(:parties) rescue nil

DB.create_table(:parties) do |t|
  t.string :theme
end

DB.create_table(:json_parties) do |t|
  if ORM_CONFIG['adapter']=='sqlite3'
    t.text :stuff
  else
    t.json :stuff
  end
end

DB.create_table(:people) do |t|
  t.integer :party_id
  t.integer :other_party_id
  t.string :name
  t.string :address
end

class Party < ActiveRecord::Base
  has_many :people
  has_many :other_people, :class_name=>'Person', :foreign_key=>'other_party_id'
end

class JsonParty < ActiveRecord::Base
  serialize :stuff, JSON if ORM_CONFIG['adapter']=='sqlite3'
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

  def insert_party_deep(times)
    times.times{JsonParty.create(:stuff=>{pumpkin: 1, candy: 1})}
  end

  def get_party_hash_deep
    if ORM_CONFIG['adapter']=='sqlite3'
      JsonParty.find_by("json_extract(stuff, '$.pumpkin') = ?", 1)
    else
      JsonParty.find_by("stuff->>'$.pumpkin' = ?", '1')
    end
  end

  def update_party_hash_deep(id)
    if ORM_CONFIG['adapter']=='postgresql'
      JsonParty.where(id: id).update_all(["stuff = jsonb_set(stuff::jsonb, '{pumpkin}', ?)", '2'])
    else
      JsonParty.where(id: id).update_all(["stuff = JSON_SET(stuff, '$.pumpkin', ?)", '2'])
    end
  end

  def update_party_hash_full(id)
    JsonParty.where(id: id).update(:stuff=>{:pumpkin=>2, :candy=>1})
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
    times.times{Party.create(:theme=>'Halloween')}
  end

  def insert_party_people(times, people_per_party)
    times.times do
      p = Party.create(:theme=>'Halloween')
      people_per_party.times{Person.create(:name=>"Party_#{p.id}", :party_id=>p.id)}
    end
  end

  def insert_party_both_people(times, people_per_party)
    times.times do
      p = Party.create(:theme=>'Halloween')
      people_per_party.times do
        Person.create(:name=>"Party_#{p.id}", :party_id=>p.id)
        Person.create(:name=>"Party_#{p.id}", :other_party_id=>p.id)
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
    DB.drop_table(:people)
    DB.drop_table(:parties)
  end

  def self.support_json?
    begin
      case ORM_CONFIG['adapter']
        when 'sqlite3'
          DB.execute('select json("{}")').to_a[0][0] == '{}'
        when 'mysql2'
          DB.execute("select JSON_OBJECT()").to_a[0][0] == '{}'
        when 'postgresql'
          DB.execute("select json_object('{}')").to_a[0]['json_object'] == '{}'
        else
          false
      end
    rescue
      false
    end
  end
end
