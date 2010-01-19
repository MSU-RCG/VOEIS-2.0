require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe "A Project" do
  
  it "should not be created without a name" do
    count = Project.all.length
    p = Project.new
    p.should_not be_valid   
    p.save
    count.should == Project.all.length
  end

  it "should be created with a name" do
    count = Project.all.length
    p = Factory.build(:project)
    p.should be_valid
    p.save
    count.should == Project.all.length - 1
  end
  
  it "should have a unique name" do
    count = Project.all.length
    p = Factory.create(:project, :name => "A Project")
    p.should be_valid
    q = Factory.build(:project, :name => "A Project")
    q.should_not be_valid
    q.save
    Project.all.length.should == count+1
  end
  
  it "should respond to to_param with the id as a string" do
    p = Project.create(:name => "Test Project")
    p.to_param.should == p.id.to_s
  end
  
  it "should respond to new_record? with its new? value" do
    p = Factory.build(:project)
    p.should be_new
    p.should be_new_record
    p.save
    p.should_not be_new
    p.should_not be_new_record
  end
  
  # This is a joke and could be removed
  it "should implement a useful method" do
    Factory.build(:project).should respond_to(:puts_moo)
  end
  
  it "should be paginated" do
    Project.should respond_to(:page_count)
    Project.should respond_to(:paginate)
  end
  
  it "should accepts a csv" # do
  #     Project.should respond_to(:upload_csv)
  #     
  #   end
  
  describe "uses a yogo Data Store" do
    
    it "should have a yogo_collection of data" do
      p = Factory.create(:project)
      p.should respond_to(:yogo_collection)
      p.yogo_collection.should be_instance_of(Yogo::Collection)
    end
    
    it "should not have a yogo_collection if it is new" do
     p = Factory.build(:project)
     p.yogo_collection.should be_nil
    end
  end
  
end