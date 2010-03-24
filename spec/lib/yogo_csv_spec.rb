require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe 'Yogo CSV Module' do
  #
  # At the project level cvs upload means creating a model and instances from a spreadsheet
  # There are a set of tests that should be done on the model creation piece, but
  # the instance creation tests overlap significantly with the yogo_models_controller csv handling.
  # 
  
  before(:all) do
    # Need a model and a CSV file.
    model = DataMapper::Model.new do
      property :yogo_id, DataMapper::Types::Serial, :field => 'id'
      property :id,   Integer,  :prefix => 'yogo'
      property :name, String,  :prefix => 'yogo'
      property :mass, Float,   :prefix => 'yogo'
      property :charge, Float, :prefix => 'yogo'
    end

    CsvExampleModel = model if !Object.const_defined?(:CsvExampleModel)
    CsvExampleModel.auto_migrate!
    
    models_path = File.dirname(__FILE__) + '/../models/csv'
    @csv_data = FasterCSV.read(models_path + '/csvtest.csv')
    @bad_csv_data = FasterCSV.read(models_path + '/bad_csvtest.csv')
    @with_blank_lines = FasterCSV.read(models_path + '/with_blank_lines.csv')
    @only_model = FasterCSV.read(models_path + '/only_model.csv')
    @one_line = FasterCSV.read(models_path + '/one_line.csv')
    @updated_csv_data = FasterCSV.read(models_path + '/updated_csv_test.csv')
    @ten_lines = FasterCSV.read(models_path + '/10_lines_of_data.csv')
  end
  
  after(:all) do
    CsvExampleModel.auto_migrate_down!
  end
  
  before(:each) do
    CsvExampleModel.auto_migrate!
  end
  
  describe 'when reading csv data' do
    it 'should validate types are valid in the spreadsheet' do
      result = Yogo::CSV.validate_csv(@csv_data)
      result.should be_empty
      result.should_not be_false
    end
    
    it "should not validate invalid csv data" do
      result = Yogo::CSV.validate_csv(@bad_csv_data)
      result.should be_kind_of(Array)
      result.should_not be_empty
      result.first.should eql("The datatype bozon for the ID column is invalid.")
    end
    
    it "should load data into a model" do
      result = Yogo::CSV.load_data(CsvExampleModel, @csv_data)
      CsvExampleModel.count.should == 3
    end
    
    it "should not load invalid data into a model" do
      result = Yogo::CSV.load_data(CsvExampleModel, @bad_csv_data)
      CsvExampleModel.count.should == 0
    end
    
    it "should ignore blank lines in data lines four and up" do
      result = Yogo::CSV.load_data(CsvExampleModel, @with_blank_lines)
      CsvExampleModel.count.should eql(3)
    end
    
    it "should not have data when just a model is present" do
      Yogo::CSV.load_data(CsvExampleModel, @only_model)
      CsvExampleModel.count.should eql(0)
    end
    
    it "should only load 1 record when there is only 1 record to load" do
      Yogo::CSV.load_data(CsvExampleModel, @one_line)
      CsvExampleModel.count.should eql(1)
      result = CsvExampleModel.first
      result.yogo__name.should eql('Sean')
      result.yogo__id.should eql(1)
      result.yogo__mass.should eql(1283.0)
      result.yogo__charge.should eql(1.2)
    end
    
    it "should update existing records with new data" do
      Yogo::CSV.load_data(CsvExampleModel, @csv_data)
      Yogo::CSV.load_data(CsvExampleModel, @updated_csv_data)
      CsvExampleModel.count.should eql(3)
      result = CsvExampleModel.get(1)
      result.yogo__name.should eql('Ivan')
      result.yogo__mass.should eql(22.0)
      result = CsvExampleModel.get(3)
      result.yogo__name.should eql('Dea')
      result.yogo__mass.should eql(23.0)
    end
  end
  
  describe "when creating CSV" do
    it "should create a template when asked" do
      Yogo::CSV.load_data(CsvExampleModel, @csv_data)
      result = Yogo::CSV.make_csv(CsvExampleModel, false)
      parsed_result = FasterCSV.parse(result)
      parsed_result.should be_kind_of(Array)
      parsed_result.length.should eql(3)
      
    end
    
    it "should create valid CSV" do
      Yogo::CSV.load_data(CsvExampleModel, @csv_data)
      result = Yogo::CSV.make_csv(CsvExampleModel, true)
      parsed_result = FasterCSV.parse(result)
      parsed_result.should be_kind_of(Array)
      parsed_result.length.should eql(6)
    end
    
    it "should load 10 lines" do
      Yogo::CSV.load_data(CsvExampleModel, @ten_lines)
      CsvExampleModel.count.should eql(10)
    end
    
  end

end