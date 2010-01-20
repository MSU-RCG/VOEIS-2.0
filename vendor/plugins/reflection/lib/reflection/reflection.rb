#require 'reflection/requirements'
require File.expand_path(File.join(File.dirname(__FILE__), 'requirements'))

module DataMapper

  module Model

    def is_reflected?
      false
    end

  end

  class Reflection

    include Databases

    @@adapter=nil, @@options=nil, @@database=nil, @@descriptions=[]

    def self.setup(options)
      defaults = {:overwrite_models => false,
        :database      => :default,
        :binding       => binding,
        :ignore        => []
      }

      @@options  = defaults.merge(options)
      @@database = DataMapper.repository(@@options[:database])
      @@adapter  = @@database.adapter

      case @@adapter.class.to_s
      when /Sqlite3/ 
        then @@adapter.extend(Databases::Sqlite3)
      when /Mysql/
        then @@adapter.extend(Databases::MySQL)
      when /Persevere/
        then @@adapter.extend(Databases::Persevere)
      when /Postgres/
        then @@adapter.extend(Databases::Postgres)
      else 
        raise "#{@@adapter.class} is not supported." 
      end
    end

    def self.descriptions
      @@descriptions
    end

    def self.add_description(description)
      @@descriptions << description
    end

    def self.options
      @@options
    end

    def self.adapter
      @@adapter
    end

    def self.append_reflected
      ["def self.is_reflected?", "true", "end"]
    end

    def self.append_default_repo_name
      ["def self.default_repository_name", ":#{@@options[:database]}", "end"]
    end

    def self.create_all_models_from_database
      k = []
      @@adapter.fetch_models.each do |model_name|
        k << create_model_from_db(model_name)
      end
      k.flatten
    end

    def self.create_model_from_db(model_name)
      describe_class(describe_model(model_name))
      generate_descriptions
    end

    def self.create_model_from_json(json, klass = nil)
      describe_class(json, klass)
      generate_descriptions
    end

    def self.create_model_from_csv(csv)
      describe_class(self::CSV.describe_model(csv))
      generate_descriptions
      #self::CSV.import_data(csv, @@options[:database])
    end

    def self.generate_descriptions
      klasses = []
      @@descriptions.each do |desc|
        puts desc
        puts "========"
        klasses << Object.class_eval(desc).model
      end
      @@descriptions.clear
      klasses
    end

    def self.handle_id(desc)
      case @@adapter.class.to_s 
      when /Persevere/
        return ["property :id, String, :key => true"] 
      else
        return ["property :id, Serial"] 
      end 
    end

    # def self.handle_namespace(id)
    #   if id.include?('/')
    #     return id.split('/')[1], id.split('/')[0]
    #   else
    #     return id, nil
    #   end
    # end

    def self.append_modules(modules)
      mods = Array.new
      modules.split('::')[0..-2].each do |mod|
        mods << "module #{mod}"
      end
      mods
    end

    def self.describe_model(model_name)
      desc = {}
      @@adapter.fetch_models.select{|model| model == model_name}.each do |model|
        attributes = @@adapter.fetch_attributes(model)
        desc.update( {'id' => "#{model}"} )
        desc.update( {'properties' => {}} )
        attributes.each do |attribute|
          if attribute.name == 'id'
            desc['properties'].update( {attribute.name => {'type' => 'String'}} )
          else
            desc['properties'].update( {attribute.name => {'type' => attribute.type}} )
          end
        end
      end
      desc.to_json
    end

    def self.describe_class(desc, klass=nil, id=nil, history=[])
      model_description = []
      desc = JSON.parse(desc) if desc.class != Hash
      history << desc['id'].split('/').map{|i| i.camel_case }.join('::') if desc['id']
      history << id if id
      class_name = klass ? klass.name + "::" : ''
      class_name += history.join('_').singularize.camel_case
      model_description << append_modules(class_name)
      model_description << "class #{class_name.split('::')[-1]}" 
      model_description << "include DataMapper::Resource"
      model_description << append_default_repo_name
      model_description << append_reflected
      model_description << handle_id(desc) unless desc['properties']['id']
      desc['properties'].each_pair do |key, value|
        if value.is_a?(Hash) && value.has_key?('properties')
          model_description << "property :#{history.join('_')}_#{key}, String"
          describe_class(value, klass, key, history)
        else
          prop = value['type'] ? \
          "property :#{key}, #{TypeParser.parse(value['type'])}" : \
          "property :#{key}, String"
          prop += ", :key => true" if key == "id"
          model_description << prop
        end
      end
      class_name.split('::').length.times do
        model_description << 'end'
      end
      @@descriptions << (model_description.join("\n"))
      return model_description.join("\n")
    end
    
    def self.make_model_string(desc, repo)
      model_description = []
      class_name = desc['id'][-1].singular.camel_case
      
      # We start the class definition by wrapping the appropriate number of module definitions
      desc['id'][0..-2].each do |mod|
        model_description << "module #{mod.capitalize.camel_case}"
      end
      
      model_description << "class #{class_name}" 
      model_description << "include DataMapper::Resource"
      model_description << "def self.default_repository_name; :#{repo}; end"
      model_description << "def self.is_reflected?; true; end"
      # This needs to be pushed into the adapter to get the appropriate serial field and extended attributes
      model_description << "property :id, Serial"
      # model_description << handle_id(desc) unless desc['properties']['id']
      desc['properties'].each_pair do |key, value|
        # This should lookup the attribute/type mapping from the adapter
        prop = value['type'] ? \
        "property :#{key}, #{TypeParser.parse(value['type'])}" : \
        "property :#{key}, String"
        prop += ", :key => true" if key == "id"
        model_description << prop
      end
      
      desc['id'].each do
        model_description << 'end'
      end
      return model_description.join("\n")
    end

    def self.reflect(repository, overwrite=false)
      adapter = DataMapper.repository(repository).adapter
      models = Array.new

#      puts "Adapter is: #{adapter.class.to_s}"
      
      # Make this behave the way migrations/aggregation work...
      case adapter.class.to_s
      when /Sqlite3/ 
        then adapter.extend(Databases::Sqlite3)
      when /Mysql/
        then adapter.extend(Databases::MySQL)
      when /Persevere/
        then adapter.extend(Databases::Persevere)
      when /Postgres/
        then adapter.extend(Databases::Postgres)
      else 
        raise "#{@@adapter.class} is not supported." 
      end
      
#      puts "Getting ready to process models from repo: #{repository}"

      # For each model
      adapter.fetch_models.each do |model|
#        puts "Model: #{model}"
        description = Hash.new
        # Get the attributes
#        puts "Fetching attributes for: #{model}"
        attributes = adapter.fetch_attributes(model)
        #description.update( {'id' => "#{model}"} )
        description.update( {'id' => model.split('/') } )
        description.update( {'properties' => {}} )
        attributes.each do |attribute|
#          puts "\t Attribute: #{attribute}"
          if attribute.name == 'id'
            description['properties'].update( {attribute.name => {'type' => 'String'}} )
          else
            description['properties'].update( {attribute.name => {'type' => attribute.type}} )
          end
        end
        desc = make_model_string(description, repository)
        models << Object.class_eval(desc).model
      end
      models
    end
  end
end