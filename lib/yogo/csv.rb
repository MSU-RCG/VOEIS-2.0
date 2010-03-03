# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: csv.rb
#
module Yogo
  class CSV
    ##
    # This method loads csv data into a model
    # 
    # @param [DataMapper::Model] model The model to load data into, creating instances of that model.
    # @param [Array of Arrays] csv_data The CSV data to create models from
    # 
    def self.load_data(model, csv_data)
      csv_data[3..csv_data.length].each do |line|
        line_data = Hash.new
        if !line.empty?
          csv_data[0].each_index do |i| 
            attr_name = csv_data[0][i].tableize.singularize.gsub(' ', '_')
            prop = model.properties[attr_name]
            line_data[attr_name] = prop.typecast(line[i]) unless line[i].nil? || prop.nil?
          end
          model.create(line_data)
        end 
      end
    end
    
    ##
    # This method validates that csv data conforms matches what the model expects.
    # 
    # @param [DataMapper::Model] model The model to validate the csv against.
    # @param [Array of Arrays] csv_data The top three rows that define the structure of the CSV file.
    # 
    # @return [Boolean] Returns true if each of the columns in the CSV corresponds to an attribute with the same type of data.
    # 
    def self.validate_csv(model, csv_data)
      prop_hash = Hash.new
      csv_data[0].each_index do |idx|
        prop_hash[csv_data[0][idx].tableize.singularize.gsub(' ', '_')] = csv_data[1][idx]
      end

      valid = true
      model.properties.each do |prop|
        valid = false unless (prop_hash.has_key?(prop.name.to_s) && 
                              prop_hash[prop.name.to_s] == Yogo::Types.dm_to_human(prop.type))
      end
      valid
    end
    
    ##
    # This method makes a csv file from a model and optionally populates that file with csv data corresponding to the instances of the model.
    # 
    # @param [DataMapper::Model] model The model that is being downloaded as a csv file.
    # @param [Boolean] include_data The boolean flag that will include all instances as data when true.
    # 
    # @return [String] Returns a string that is formatted as a CSV file that can be read back in by the Yogo Toolkit.
    # 
    def self.make_csv(model, include_data=false)
      csv_output = FasterCSV.generate do |csv|
        csv << model.properties.map{|prop| prop.name.to_s.humanize}
        csv << model.properties.map{|prop| Yogo::Types.dm_to_human(prop.type)}
        csv << "Units will go here when supported"
      end

      model.all.each { |m| csv_output << m.to_csv } if include_data
      
      csv_output
    end
  end # class CSV
end # module Yogo