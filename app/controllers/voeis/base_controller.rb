require 'responders/rql'

# @author Ryan Heimbuch
# @abstract Base class for Voeis-specific controllers
#
# Voeis models are not "related" to Project as might be expected by the
# InheritedResources#belongs_to declaration.
# In fact, Voeis models have no relationship with the top-level
# Project model.
# Instead Project acts as a RepositoryManager and handles creating
# and manipulating a "project-specific" DataMapper::Repository
# that other Voeis models will store their data into.
# @see Project
# @see Yogo::DataMapper::RepositoryManager
#
# This controller class overrides methods from InheritedResources::Base
# in order to handle the behavior introduced by Project and RepositoryManager.
#
# When subclassing, you may need to specify certain 'defaults', especially
# if the underlying model is namespaced (Voeis::SomeModel).
#
# @example Subclass Voeis::BaseController
#   class Voeis::UnitsController < Voeis::BaseController
#     defaults  :route_collection_name => 'units',
#               :route_instance_name => 'unit',
#               :collection_name => 'units',
#               :instance_name => 'unit',
#               :resource_class => Voeis::Unit
#   end
#
# These overrides are not specific to Voeis::BaseController, but
# instead come from InheritedResources::Base.
# You should be familiar with the features provided by InheritedResources
# and understand how to properly override the controller actions (index/create/edit/...etc).
# @see http://github.com/josevalim/inherited_resources/tree/v1.0.6
class Voeis::BaseController < InheritedResources::Base

  # #belongs_to indicates that the resources managed by this controller
  # are nested-resources under /project/.
  # This **does not** mean that any of the resources have any database
  # relationship with Project.
  belongs_to :project, :parent_class => Project, :finder => :get

  # All Voeis resources should handle html and json
  respond_to :html, :json, :xml, :wml

  responders :rql
  
  require 'action_controller/metal/renderers'
  
  
  ActionController::Renderers.add :wml do |object, options|
    self.content_type ||= 'text/waterml'
    self.response_body  = object.respond_to?(:to_wml) ? object.to_wml : object.to_xml
  end
  
  require 'action_controller/metal/responder'
  class ActionController::Responder
    def to_wml
      controller.render :wml => resource
    end
  end
  
  # before_filter proc { |controller|
  #    if params[:format] && params[:format]=='wml' && controller.collect_mimes_from_class_level.include?(:wml)
  #      controller.action_has_layout = false
  #      controller.request.format    = 'xml'
  #      render :xml => data_obj.to_wml
  #    end
  #  }
  
  # # to add it to only one action
  # active_scaffold do |config|
  #   config.index.formats << :wml
  # end
  # 
  # def show_respond_to_wml
  #   #render whatever you want here
  #   render :xml => data_obj.to_wml
  # end

  protected

  # Retrieve, caches, and returns the resource indicated by param[:id]
  # The resource returned will be retrieved from the repository managed
  # by the current Project (#parent).
  def resource
    get_resource_ivar || set_resource_ivar( parent.managed_repository{ collection.get(params[:id]) } )
  end

  # Retrieve the resource collection.
  # Collections are retrieved from the repository managed by
  # the current Project (#parent).
  def collection
    get_collection_ivar || set_collection_ivar( parent.managed_repository{ resource_class.all } )
  end

  # Build a new resource.
  # The new resource will be stored in the repository managed by
  # the current Project (#parent).
  # @see Project#build_managed
  def build_resource
    get_resource_ivar || set_resource_ivar(parent.build_managed(resource_class, params[resource_instance_name] || {}))
  end

  # Create a resource in the Project#managed_repository
  def create_resource(object)
    parent.managed_repository {
      object.save
    }
  end

  # Update a resource in the Project#managed_repository
  def update_resource(object, attributes)
    parent.managed_repository {
      object.attributes = attributes
      object.save
    }
  end

  # Destroy a resource in the Project#managed_repository
  def destroy_resource(object)
    parent.managed_repository {
      object.destroy
    }
  end

  def parent
    p = super
    return p if p.is_facet?
    return p.access_as(current_user) if p.respond_to?(:access_as)
    return p
  end
end
