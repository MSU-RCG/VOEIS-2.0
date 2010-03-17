# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: data_methods.rb
# 
module Yogo
  module DataMethods
    @@reserved_names = ["id"]
    
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.class_eval do

        base.properties.each do |property|
          # Create carrierwave class for this property.
          if property.type == DataMapper::Types::YogoFile
            path = Rails.root / 'public' / 'files' 
            self.name.split('::').each{ |mod| path = path / mod }
            storage_dir = path.to_s
            anon_file_handler = Class.new(CarrierWave::Uploader::Base)
            anon_file_handler.instance_eval do 
              storage :file
              
              self.class_eval("def store_dir; '#{path}'; end")
              
            end
            
            named_class = Object.class_eval("#{self.name}::#{property.name.to_s.camelcase}File = anon_file_handler")
            mount_uploader property.name, named_class

          end
        end
      end
    end
    
    def self.map_attribute(name)
      @@reserved_names.include?(name) ? "yogo___"+name : name
    end
    
    module ClassMethods
      def usable_properties
        properties.select{|p| p.name != :yogo_id }
      end
    end
  end
end