# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: loader.rb
# 
module Yogo
  class Loader
    ##
    # Loads a repository into a new project
    #
    # @example TODO
    #
    # @param [Slug] repo the repository to load the project from
    # @param [String] name the project name in normal form, e.g. "Example Project"
    #
    # @return [Model] load a repository into a new project
    # 
    # @author Yogo Team
    #
    # @api public
    def self.load(repo, name)
      project = Project.create(:name => name)
      
      # Iterate through each model and make it in persevere, then copy instances
      models = DataMapper::Reflection.reflect(repo, Object, true)
      
      yogo_models = Array.new
      
      # Create models
      models.each do |model|
        mphash = {}
        
        model.properties.each do |prop| 
          type = prop.type == String ? DataMapper::Types::Text : prop.type
          mphash[prop.name] = { :type => type } 
          mphash[prop.name].merge!({:default => prop.default}) if prop.default? 
        end
        ym = project.add_model(model.name, mphash)
        yogo_models << ym
        ym.auto_migrate!
      end
      
      # Wire up relationships
      models.each_index do |idx|
        model = models[idx]
        yogo_model = yogo_models[idx]
        model.relationships.each do |key,relation|
          other = yogo_models[models.index(models.select { |item| item.name == relation.child_model_name }[0])]
          case relation
          when DataMapper::Associations::ManyToMany::Relationship
            puts "Making M:M (Infinity) #{key.to_sym} (:through => Resource) with model: #{other}"
            yogo_model.has(Infinity, key.to_sym, {:through => DataMapper::Resource, :model => other, :prefix => "yogo", :separator => "__"})
          when DataMapper::Associations::OneToMany::Relationship
            puts "Making 1:M (Infinity) #{key.to_sym} with model: #{other}"
            yogo_model.has(Infinity, key.to_sym, {:model => other, :prefix => "yogo", :separator => "__"})
          when DataMapper::Associations::ManyToOne::Relationship
            other = yogo_models[models.index(models.select { |item| item.name == relation.parent_model_name }[0])]
            puts "Making M:1 (belongs_to) #{key.singularize.to_sym} with model: #{other}"
            yogo_model.belongs_to(key.singularize.to_sym, {:model => other, :prefix => "yogo", :separator => "__"})
          when DataMapper::Associations::OneToOne::Relationship
            puts "Making 1:1 #{key.singularize.to_sym} with model: #{other}"
            yogo_model.has(1,key.singularize.to_sym, {:model => other, :prefix => "yogo", :separator => "__"})
          end
        end
      end
            
      debugger
      
      # Migrate them now that they're full of properties and relationships
      yogo_models.each do |model|
        model.auto_upgrade!
      end      
            
      # Load up instances
      models.each_index do |idx|        
        model = models[idx]
        yogo_model = yogo_models[idx]
        model.all.each do |item|
          newitems = Hash.new
          item.attributes.each_pair do |attr, val|
            newitems["yogo__#{attr}"] = val
          end
          yogo_model.create(newitems)
        end
      end
      
      # Load up instance relationships
      yogo_models.each do |yogo_model|        
        model = models[models.index(yogo_model.name.demodulize.constantize)]
        relationships = model.relationships.keys
        model.all.each do |instance|
          yogo_instance = yogo_model.first(:yogo__id => instance.id)
          relationships.each do |r|
            if model.relationships[r].max == 1
              puts "Getting #{r} data for #{instance}"
              value = instance.send(r.to_sym)
              yogo_value = yogo_models[models.index(value.model)].first(:yogo__id => value.id)
              yogo_instance.send("#{r}=".to_sym, yogo_value)
            else
              puts "Getting #{r} data for #{instance}"
              values = instance.send(r.to_sym)
              next if values.length == 0
              yogo_values = values.map { |v| yogo_models[models.index(v.model)].first(:yogo__id => v.id) }

              if yogo_model.relationships[r].is_a?(DataMapper::Associations::ManyToMany::Relationship)
                puts "M:M Set"
              else
#                debugger
                puts "1:M Set"
#                yogo_instance.send("#{r}=".to_sym, yogo_values)
              end
            end
          end
          yogo_instance.save
        end
      end

      # Nuke origional reflected models
      models.each do |model|
        DataMapper::Model.descendants.delete(model)
        Object.send(:remove_const, model.name.to_sym) 
      end
      
      DataMapper::Reflection.reflect(:default)
    end
  end
end