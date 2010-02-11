# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: factory.rb
# This Factory builds DataMapper models 
#
module DataMapper
  class Factory
    
    # This will look for a hash with certain keys in it. Those keys are:
    # * :modules    =>  [], and array of modules the class will be namespaced into by the order they are in the array
    # * :name       =>  'ClassName' The name of the class in camel case format.
    # * :properties =>  {}, a hash of properties
    # 
    #     Each key in the property hash is the name of the property.
    #     if the key points to a string or symbol, that will be used as the property type.
    #     The property type should be a valid DataMapper property type.
    #--
    #     If the key points to a hash, dum, Dum, DUM!? What will happen?!
    #
    #  TODO : Implement support for relationships/associations
    # :associations => {} associations this class has with other classes.
    #++
    # This returns a datamapper model. 
    def self.build(desc, repository_name = :default, options = {})
      module_names = desc[:modules] || []
      class_name   = desc[:name]
      properties   = desc[:properties]
      full_name    = (module_names + [class_name]).join('::')
      
      # Create the scoping for the class, if it doesn't already exist.
      current_context = Object
      module_names.each do |mod|
        current_context.const_set(mod, Module.new) unless current_context.const_defined?(mod)
        current_context = Object.class_eval("#{current_context.name}::#{mod}", __FILE__, __LINE__)
      end

      if current_context.const_defined?(class_name) # && options[:overwrite] == true
        cur_class = current_context.const_get(class_name)
        DataMapper::Model.descendants.delete(cur_class)
        current_context.send(:remove_const, class_name.to_sym)
      end

      # Define our anonymous class, anonymously.
      anon_class = DataMapper::Model.new do 
        self.class_eval("def self.default_repository_name; :#{repository_name}; end")
        properties.each_pair do |property, opts|
          if opts.is_a?(Hash)
            opts[:type] = :'DataMapper::Types::Serial' if opts[:type].to_s == 'Serial'
            property( property.to_sym, eval(opts[:type].to_s), opts.reject{|k,v| k == :type })
          else
            opts = :'DataMapper::Types::Serial' if opts.to_s == 'Serial'
            property( property.to_sym, eval(opts.to_s))
          end
        end
      end

      # Give the class a name.
      named_class = current_context.const_set(class_name, anon_class)
      
      named_class.send(:include, options[:modules]) if options.has_key?(:modules)
      return named_class
    end

    # This accepts class_name ("Yogo::Example::SomeName") and a 2-dimensional
    # array containing the first three line of a CSV file.
    #
    # The array should contain:
    # 1. property names in [0][]
    # 2. property types in [1][]
    # 3. property units in [2][] - currently unsupported
    # 
    # Returns a DataMapper model with properties defined by spec_array
    def self.make_model_from_csv(class_name, spec_array)
      scopes = class_name.split('::')
      spec_hash = { :name => scopes[-1], :properties => Hash.new }
      spec_hash[:modules] = scopes[0..-2] unless scopes.length.eql?(1)                  
      spec_array[0].each_index do |idx|
        prop_hash = Hash.new
        pname = spec_array[0][idx].tableize.singular.gsub(' ', '_')
        ptype = Yogo::Types.human_to_dm(spec_array[1][idx])
        punits = spec_array[2][idx]
        if pname == 'id'
          prop_hash = { pname => { :type => DataMapper::Types::Serial } }
        else
          prop_hash = { pname => { :type => ptype, :required => false } }
        end
        spec_hash[:properties].merge!(prop_hash) 
      end
      # puts "CSV Spec Hash: #{spec_hash.inspect}"
      self.build(spec_hash, :yogo)
    end
    
  end# class Factory
end # module DataMapper