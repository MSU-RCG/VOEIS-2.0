require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe "A Yogo::Collection" do
  
  before(:each) do
    @valid_yogo_collection = Yogo::Collection.new
  end
  
  it "should return an array of schemas with #yogo_schema" do
    yc = @valid_yogo_collection
    yc.should respond_to(:yogo_schema)
    yc.yogo_schema.should_not be_nil
    yc.yogo_schema.should be_instance_of(Array)
    yc.yogo_schema.first.should be_instance_of(Yogo::Schema)
  end
  
  it "should have data for the schema" do
    ys = @valid_yogo_collection.yogo_schema.first
    ys.yogo_data.should_not be_nil
    ys.yogo_data.should be_instance_of(Array)
    ys.yogo_data.length.should == 10
  end
  
  it "should save data for a schema" do
    yc = @valid_yogo_collection
    d = Yogo::Data.new
    yc.yogo_schema('Person').yogo_data << d
    yc.save
    yc.yogo_schema('Person').yogo_data.should be_include(d)
  end
  
  it "should retrieve data for a schema" do
    # populate it with some data?
    @valid_yogo_collection.yogo_data('Person').length.should == 10
  end
  
  it "should be invalid without a project" do
    count = Yogo::Collection.all.length
    yc = Yogo::Collection.new
    yc.should_not be_valid
    yc.save
    Yogo::Collection.all.length.should == count
  end
  
  it "should save with valid attributes" do
    count = Yogo::Collection.all.length
    yc = Yogo::Collection.new(:project_id => 1)
    yc.should be_valid
    yc.save
    Yogo::Collection.all.length.should == count+1
  end
  
  
end