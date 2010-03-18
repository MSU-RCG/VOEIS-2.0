require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

def mock_uploader(file, type = 'text/csv')
  filename = "%s/%s" % [ File.dirname(__FILE__), file ]
  uploader = ActionController::UploadedStringIO.new
  uploader.original_path = filename
  uploader.content_type = type
  def uploader.read
    File.read(original_path)
  end
  def uploader.size
    File.stat(original_path).size
  end
  uploader
end

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
    p = Factory.create(:project, :name => "Test Original Name")
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

  it "should create a namespace from the project id and name (with non-alphas stripped)" do
    ['Test:Project', 'Test Project', 'Test&Project', 'Test!Project'].each do |name|
      p = Project.create(:name => name)
      p.namespace.match(/[^\w]/).should be_nil
      p.destroy!
    end
  end

  it "should be paginated" do
    Project.should respond_to(:page_count)
    Project.should respond_to(:paginate)
  end

  describe "searching" do
    it "should be searchable" do
      Project.should respond_to(:search)
    end
    
    it "should search for a project by a name" do
      Project.create(:name  => "Searchable Name")
      Project.search('Name').length.should == 1
    end
    
    it "should search with spaces" do
      Project.create(:name => "A Long Name")
      Project.search('A Long Name').length.should == 1
    end
    
  end

  it "should process a csv file" do
    file_name = "#{Rails.root}/spec/models/csv/csvtest.csv"
    p = Factory.create(:project)
    p.process_csv(file_name, 'Csvtest').should be_empty
    results = p.search_models('csvtest')
    results.should be_an Array
    results.length.should eql(1)
    results[0].name.should eql("Yogo::#{p.namespace}::Csvtest")
    
  end

  it "should not process a bad csv file" do
    file_name = "#{Rails.root}/spec/models/csv/bad_csvtest.csv"
    p = Factory.create(:project)
    errors = p.process_csv(file_name, 'Csvtest')
    errors.should_not be_empty
  end

  it "should not overwrite a model that already exists" do
    file_name = "#{Rails.root}/spec/models/csv/csvtest.csv"
    p = Factory.create(:project)
    p.process_csv(file_name, 'Csvtest')
    results = p.search_models('csvtest')
    results.should be_an Array
    results.length.should eql(1)
    results[0].name.should eql("Yogo::#{p.namespace}::Csvtest")
    
    "Yogo::#{p.namespace}::Csvtest".constantize.should_not be_nil
    old_count = results[0].count
    
    p.process_csv(file_name, 'Csvtest')
    results2 = p.search_models('csvtest')
    results2.should be_an Array
    results2.length.should eql(1)
    results2[0].name.should eql("Yogo::#{p.namespace}::Csvtest")
    results2[0].count.should eql(old_count*2)
  end

  describe 'importing from csv' do
    # it "should create a model from a csv" do
    #   file_name = "#{Rails.root}/spec/models/csv/csvtest.csv"
    #   model_name = File.basename(file_name, ".csv").camelcase
    #   csv_data = FasterCSV.read(file_name)
    #   model = @factory.make_model_from_csv(model_name, csv_data[0..2])
    #   Object.const_defined?(model_name).should be_true
    # end
    # 
    # it "should import data from csv" do
    #   file_name = "#{Rails.root}/spec/models/csv/csvtest.csv"
    #   model_name = File.basename(file_name, ".csv").camelcase
    #   csv_data = FasterCSV.read(file_name)
    #   model = @factory.make_model_from_csv(model_name, csv_data[0..2])
    #   model.auto_migrate!
    #   csv_data[3..-1].each do |line| 
    #     line_data = Hash.new
    #     csv_data[0].each_index { |i| line_data[csv_data[0][i].downcase] = line[i] }
    #     model.create(line_data)
    #   end
    #   model.first(:name => "Bug").should be_true
    #   model.auto_migrate_down!
    # end
  end

  describe "contains references to reflected datamapper models" do
    it "should contain an array of reflected models" do
      p = Factory.build(:project)
      p.should respond_to(:models)
      p.models.should_not be_nil
      p.models.should be_instance_of(Array)
      p.models.each do |m|
        m.should be_instance_of(DataMapper::Property)
      end
    end

    it "should respond to an add_model method that creates a model" do
      project = Project.create(:name => "Test Project 1")
      model_hash = { 
        :name => "Cell",
        :modules => ["Yogo", "TestProject1"],
        :properties => {
          "name" => {:type => "String"},
          "id"   => {:type => "Serial"}
        }
      }
      m = project.add_model(model_hash)
      m.should == Yogo::TestProject1::Cell
      Yogo::TestProject1::Cell.ancestors.should include(DataMapper::Resource)
    end

    it "should make the newly added model available via .models" do
      project = Factory.create(:project, :name => "Test Project 1")
      model_hash = { 
        :name => "Cell",
        :modules => ["Yogo", "TestProject1"],
        :properties => {
          "name" => {:type => "String"},
          "id"   => {:type => "Serial"}
        }
      }
      project.add_model(model_hash)
      model_names = project.models.map(&:name)
      model_names.map{|m| m.match(/^Yogo::#{project.namespace}::Cell/)}.compact.should_not be_empty
    end


    it "should properly namespace an un-namespaced model hash" do
      project = Factory.create(:project, :name => "Test Project 2")
      model_hash = { 
        :name => "Monkey",
        :modules => ["Yogo", "TestProject2"],
        :properties => {
          "name" => {:type => "String"},
          "id"   => {:type => "Serial"}
        }
      }
      project.add_model(model_hash)
      model_names = project.models.map(&:name)
      model_names.map{|m| m.match(/^Yogo::#{project.namespace}::Monkey/)}.compact.should_not be_empty
    end

    it "should save a valid schema which should be persisted to the datastore" do
      # This is already in the test database and should be pre-populated for 
      # the above project
      persisted_model_hash = { 
        "id" => "yogo/persisted_data/cell",
        "properties" => {
          "name" => {"type" => "string"}
        }
      }
      # debugger
      # repository.adapter.delete_schema(persisted_model_hash)
      repository.adapter.put_schema(persisted_model_hash)
      project = Factory(:project, :name => 'Persisted Data')
      project.models.should == []
      models = DataMapper::Reflection.reflect(:default)
      project.models.map(&:name).should == ["Yogo::PersistedDatum::Cell"]
      project.delete_models!
      project.destroy
      
    end

    it "should be able to delete its schemas" do
      persisted_model_hash = { 
        "id" => "yogo/persisted_bozon/cell",
        "properties" => {
          "name" => {"type" => "string"}
        }
      }
      repository.adapter.put_schema(persisted_model_hash)
      project = Factory(:project, :name => 'Persisted Bozon')
      DataMapper::Reflection.reflect(:default)
      project.models.should_not be_empty
      project.delete_models!
      project.models.should be_empty
    end
  end

  it "should not save an invalid schema and return nil"
end