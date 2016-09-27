require 'mongoid'
if ORM_CONFIG['debug']
  Mongoid.logger.level = Logger::DEBUG
  Mongo::Logger.logger.level = Logger::DEBUG
else
  Mongoid.logger.level = Logger::INFO
  Mongo::Logger.logger.level = Logger::INFO
end
Mongoid.configure do |config|
  config.connect_to(ORM_CONFIG['database'])
end
Mongoid::Clients.default.database.drop

class Party
  include Mongoid::Document
  field :theme, type: String

  has_many :people, :foreign_key=>'party_id'
  has_many :other_people, :class_name=>'Person', :foreign_key=>'other_party_id'
end

class JsonParty
  include Mongoid::Document
  field :stuff, type: Hash
end

class Person
  include Mongoid::Document
  field :name, type: String
  field :address, type: String
  field :party_id, type: BSON::ObjectId
  field :other_party_id, type: BSON::ObjectId

  belongs_to :party, :inverse_of=>'people'
  belongs_to :other_party, :class_name=>'Party', :inverse_of=>'other_people'
end

class Bench
  def delete_all
    Mongoid::Clients.default.database.drop
  end

  def all_parties
    Party.all
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
    JsonParty.find_by('stuff.pumpkin'=>1)
  end

  def update_party_hash_deep(id)
    JsonParty.where(id: id).set(:stuff=>{:pumpkin=>2})
  end

  def update_party_hash_full(id)
    JsonParty.where(id: id).update(:stuff=>{:pumpkin=>2, :candy=>1})
  end

  def eager_graph_party_both_people
    Party.includes(:people, :other_people).each{|party| party.people.each{|p| p.id}; party.other_people.each{|p| p.id}}
  end

  def eager_graph_party_people
    Party.includes(:people).each{|party| party.people.each{|p| p.id}}
  end

  def eager_load_party_both_people
    Party.includes(:people, :other_people).each{|party| party.people.each{|p| p.id}; party.other_people.each{|p| p.id}}
  end

  def eager_load_party_people
    Party.includes(:people).each{|party| party.people.each{|p| p.id}}
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
      people_per_party.times{Mongoid::Clients.default[:people].insert_one({:name=>"Party_#{p.id}",:party_id=>p.id})}
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
    DB.transaction(&block)
  end

  def with_connection
    yield
  end

  def self.drop_tables
    Mongoid::Clients.default.database.drop
  end

  def self.support_json?
    true
  end
end
