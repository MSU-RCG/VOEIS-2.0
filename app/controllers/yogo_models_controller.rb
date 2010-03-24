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

  # Provides a list of the models for the current project
  # 
  def index
    @models = @project.models
    
    respond_to do |format|
      format.html
      format.json { render( :json => "[#{@models.collect{|m| m.to_json_schema }.join(', ')}}" )}
    end
  end
  
  # Display a model schema with Human readable datatypes
  #
  def show
    @model = @project.get_model(params[:id])

    respond_to do |format|
      format.html
      format.json { render( :json => @model.to_json_schema )}
      format.csv { download_csv }
    end

  end
  
  def new
    @model = Class.new
    
    @options = Yogo::Types.human_types.map{|key| [key,key] }
  end
  
  def create
    class_name = params[:class_name].titleize.gsub(' ', '')
    cleaned_options = {}
    errors = {}
    
    params[:new_property].each do |prop|
      name = prop[:name].squish.downcase.gsub(' ', '_')
      prop_type = Yogo::Types.human_to_dm(prop[:type])
      prop_pos = prop[:position]
      
      next if name.blank?
      
      if valid_model_or_column_name?(name) && !prop_type.nil?
        pfield = Yogo::DataMethods.map_attribute(name)
        cleaned_options[name] = { :type => prop_type, :position => prop_pos, :field => pfield }
      else #error
        errors[name] = " is a malformed name or an invalid type."
      end
    end
    
    @model = false
    
    if errors.empty? and (@model = @project.add_model(class_name, :properties => cleaned_options)) != false
      @model.send(:include,Yogo::DataMethods) unless @model.included_modules.include?(Yogo::DataMethods)
      @model.auto_migrate!
      @model.properties.sort!
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
    @options = Yogo::Types.human_types.map{|key| [key,key] } 
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
      next if prop[:name].empty? || prop[:type].empty?
      name = prop[:name].squish.downcase.gsub(' ', '_')
      prop_type = Yogo::Types.human_to_dm(prop[:type])
      prop_pos = prop[:position]
      
      next if name.blank?
      
      if valid_model_or_column_name?(name) && !prop_type.nil?
        pfield = Yogo::DataMethods.map_attribute(name)
        cleaned_params << [name, prop_type, prop_pos, pfield]
      else #error
        errors[name] = " is a malformed name or an invalid type."
      end
    end unless params[:new_property].nil?
    
    params[:property].each_pair do |prop, options|
      name = prop.squish.downcase.gsub(' ', '_')
      prop_type = Yogo::Types.human_to_dm(options[:type])
      prop_pos = options[:position]
      
      if valid_model_or_column_name?(name) && !prop_type.nil?
        pfield = Yogo::DataMethods.map_attribute(name)
        cleaned_params << [name, prop_type, prop_pos, pfield]
      else #error
        errors[name] = " is a malformed name or an invalid type."
      end
    end

    # Type Checking
    if errors.empty?
      cleaned_params.each do |prop|
        @model.send(:property, prop[0].to_sym, prop[1], :required => false, :position => prop[2], :field => prop[3], :separator => '__', :prefix => 'yogo')
      end
      
      @model.auto_upgrade!
      @model.properties.sort!
      @model.send(:include,Yogo::DataMethods)
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
    redirect_to project_url(@project)
  end
  
  def list_attributes
    @model = @project.get_model(params[:id])
    @attributes = Yogo::Navigation.attributes(@model)
    
    respond_to do |wants|
      wants.html 
      wants.js { render(:partial => 'list_attributes', :locals => { :model => @model, :attributes => @attributes, :project => @project })}
    end
  end
  
  private
  
  # Allows download of yogo project model data in CSV format
  # 
  def download_csv
    send_data(Yogo::CSV.make_csv(@model, false), 
              :filename    => "#{@model.name.demodulize.tableize.singular}.csv", 
              :type        => "text/csv", 
              :disposition => 'attachment')
  end
  
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