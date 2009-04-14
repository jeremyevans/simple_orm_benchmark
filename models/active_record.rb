require 'active_record'
ActiveRecord::Base.establish_connection(YAML.load_file("db.yml"))

c = ActiveRecord::Base.connection
c.drop_table(:parties) rescue nil
c.create_table(:parties) do |t|
  t.string :theme
end

c.drop_table(:people) rescue nil
c.create_table(:people) do |t|
  t.integer :party_id
  t.string :name
  t.string :address
end

class Party < ActiveRecord::Base
  has_many :people
  
  def self.eager_load_people
    find(:all, :include=>:people).each{|party| party.people.size }
  end
end

class Person < ActiveRecord::Base  
  belongs_to :party
end
