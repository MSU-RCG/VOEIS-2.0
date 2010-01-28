# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: yogo_models_controller.rb
# Functionality for CRUD of yogo project models
# 
class YogoModelsController < ApplicationController
  before_filter :find_parent_items
  

  # Constant for the supported Human readable datatypes
  HumanTypes = { "Decimal"        => BigDecimal, 
                  "Integer"        => Integer,
                  "Text"           => String, 
                  "True/False"     => DataMapper::Types::Boolean, 
                  "Date"           => DateTime }
  
  # Provides a list of the models for the current project
  # 
  def index
    @models = @project.models
  end
  
  # Display a model schema with Human readable datatypes
  #
  def show
    @model = @project.get_model(params[:id])
    @types = HumanTypes.invert
  end
  
  def new
    # This is an attempt to make a mock object to work with in the editor.
    if Struct.const_defined?('PrototypeModel')
      @model = Struct::PrototypeModel
    else
      @model = Struct.new('PrototypeModel')
    end
    
    @options = HumanTypes.keys.collect{|key| [key,key] }
    
  end
  
  def create
    class_name = params[:class_name].titleize.gsub(' ', '')
    cleaned_options = {}
    # params[:name]
    errors = {}
    
    params[:new_property].each do |prop|
      name = prop[:name].squeeze.gsub(' ', '_').tableize
      prop_type = HumanTypes[prop[:type]]
      
      next if name.blank?
      
      if valid_model_or_column_name?(name) && !prop_type.nil?
        cleaned_options[name] = prop_type
      else #error
        errors[name] = " is a malformed name or an invalid type."
      end
    end
    
    @model = false
    
    if errors.empty? and (@model = @project.add_model(class_name, :properties => cleaned_options)) != false
      @model.auto_migrate!
      flash[:notice] = 'The model was sucessfully created.'
      redirect_to(project_yogo_model_url(@project, @model.name.demodulize))
    else
      flash[:notice] = 'There were errors creating your model'
      flash[:model_errors] = errors
      redirect_to( new_project_yogo_model_url(@project) )
    end
  end
  
  # Allows a user to add a field/property to an existing model
  #
  def edit
    @model = @project.get_model(params[:id])
    @options = HumanTypes.keys.collect{|key| [key,key] }
    @types = HumanTypes.invert
  end

  # Processes adding a field/property to an existing model
  # 
  # * models are migrated up so no data is lost
  def update
    @model = @project.get_model(params[:id])
    # This stuff need to be pushed down into the model. In due time.
    errors = {}
    cleaned_params = []
    
    params[:new_property].each do |prop|
      name = prop[:name].squeeze.downcase.gsub(' ', '_')
      prop_type = HumanTypes[prop[:type]]
      
      next if name.blank?
      
      if valid_model_or_column_name?(name) && !prop_type.nil?
        cleaned_params << [name, prop_type]
      else #error
        errors[name] = " is a malformed name or an invalid type."
      end
    end
    
    params[:property].each_pair do |prop, type|
      name = prop.squeeze.gsub(' ', '_')
      prop_type = HumanTypes[type]
      
      if valid_model_or_column_name?(name) && !prop_type.nil?
        cleaned_params << [name, prop_type]
      else #error
        errors[name] = " is a malformed name or an invalid type."
      end
    end
    
    # Type Checking
    if errors.empty?
      cleaned_params.each do |prop|
        
        @model.send(:property, prop[0].to_sym, prop[1], :required => false)
      end
      
      @model.auto_upgrade!
      flash[:notice] = "Properties added"
      
      redirect_to project_yogo_model_url(@project, @model.name.demodulize)
    else
      flash[:notice] = "Properties were not added."
      flash[:model_errors] = errors
      redirect_to edit_project_yogo_model_url(@project, @model.name.demodulize)
    end

  end  
  
  # Removes a model from the project (including data)
  # 
  # * The table and data associated with this model will be removed from the repo
  def destroy
    model = @project.get_model(params[:id])
    @project.delete_model(model)
    redirect_to project_yogo_models_url(@project)
  end
  
  private
  
  # Sets @project to the current project_id parameter
  #
  def find_parent_items
    @project = Project.get(params[:project_id])
  end
  
  # TODO: Validations shoulnd't be here.
  def valid_model_or_column_name?(potential_name)
    !potential_name.match(/^\d|\.|\!|\@|\#|\$|\%|\^|\&|\*|\(|\)|\-/)
  end
end