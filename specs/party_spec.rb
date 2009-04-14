require File.join(File.dirname(__FILE__), "..", "lib", "party")

describe Party do
  it "should initialize a party" do
    p=Party.new
    p.should be_an_instance_of(Party)
  end

  it "should be associated to parties" do
    Party.table_name.should eql(:parties)
  end
end
