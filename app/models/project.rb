 # Yogo Data Management Toolkit
 # Copyright (c) 2010 Montana State University
 #
 # License -> see license.txt
 #
 # FILE: project.rb
 # The project model is where the action starts.  Every yogo instance starts with a 
 # a project and the project is where the models and data will be namespaced.
 #

class Project
  include DataMapper::Resource
  include Yogo::Pagination
  
  property :id, Serial
  property :name, String, :required => true
  
  validates_is_unique   :name
  
  before :destroy, :delete_models!

  # Returns the project namespaced name
  #
  def namespace
    name.split(/\W/).map{ |item| item.capitalize}.join("")
  end
  
  # Returns the project path name
  #
  def path
    name.downcase.gsub(/[^\w]/, '_')
  end
  
  # to_param is called by rails for routing and such
  def to_param
    id.to_s
  end
  
  # Creates a model and imports data from a CSV file
  #
  # * The csv datafile must be in the following format: 
  #   1. row 1 -> field names
  #   2. row 2 -> type, 
  #   3. row 3 -> units
  #   4. rows 4+ -> data
  # 
  def process_csv(datafile)
    # Read the data in
    csv_data = FasterCSV.read(datafile.path)

    # Get Model name
    model_name = "Yogo::#{namespace}::#{File.basename(datafile.original_filename, ".csv").singularize.camelcase}"
    
    # Process the contents
    model = DataMapper::Factory.make_model_from_csv(model_name, csv_data[0..2])
    model.auto_migrate!
    
    csv_data[3..-1].each do |line| 
      line_data = Hash.new
      csv_data[0].each_index { |i| line_data[csv_data[0][i].downcase] = line[i] }
      model.create(line_data)
    end
  end
  
  # Returns an array of the models associated with current project namespace
  #
  def models
    DataMapper::Model.descendants.select { |m| m.name =~ /Yogo::#{namespace}::/ }
  end
  
  # Returns a models name from the  "name"
  #
  # * The csv datafile must be in the following format:
  # =Example
  #  
  def get_model(name)
    DataMapper::Model.descendants.select{|m| m.to_s.split('::')[-1] == name }[0]
  end

  # Adds a model to the current project
  #
  # * "hash" contains all the modules, name and properties to define the model
  # 
  def add_model(hash)
    DataMapper::Factory.build(hash, :yogo)
  end
  
  # Removes a model and all of its data from a project
  #
  #
  def delete_model(model)
    model = get_model(model) if model.class == String
    name = model.name.demodulize
    model.auto_migrate_down!

    DataMapper::Model.descendants.delete(model)
    n = eval("Yogo")
    if n.constants.include?(namespace.to_sym) 
      ns = eval("Yogo::#{namespace}")
      ns.send(:remove_const, name.to_sym) if ns.constants.include?(name.to_sym)
    end
  end

  # Removes all models and all of the data from a project
  #
  # * performed before project.destroy
  def delete_models!
    models.each do |model|
      delete_model(model)
    end
  end
end
