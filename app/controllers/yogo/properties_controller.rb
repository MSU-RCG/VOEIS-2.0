class Yogo::PropertiesController < Yogo::BaseController
  defaults :collection_name => 'schema',
           :instance_name => 'property'
           
  belongs_to :project, :parent_class => Yogo::Project, :finder => :get do
    belongs_to :data_collection, :parent_class => Yogo::Collection::Data, :finder => :get, :param => :collection_id
  end

  protected
  
  def collection
    @schema ||= end_of_association_chain.all
  end
  
  def resource
    @property ||= collection.get(params[:id])
  end
  
  with_responder do
    def resource_json(resource)
      data_collection = resource.data_collection
      project = data_collection.project
      hash = resource.as_json
      hash[:uri] = controller.send(:yogo_project_collection_property_path, project, data_collection, resource)
      hash[:data_collection] = controller.send(:yogo_project_collection_path, project, data_collection)
      hash
    end
    
    def collection_json(collection)
      collection.map do |prop|
        data_collection = prop.data_collection
        project = data_collection.project
        controller.send(:yogo_project_collection_property_path, project, data_collection, prop)
      end
    end
  end
  
end