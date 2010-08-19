
# SensorTypes
#
require 'yogo/datamapper/model/storage_context'
class Voeis::SensorType
  include DataMapper::Resource
  extend Yogo::DataMapper::Model::StorageContext

  property :id, UUID,       :key => true, :default => lambda { UUIDTools::UUID.timestamp_create }
  property :name,     String,  :required => true
  property :min,      Float,  :required => false
  property :max,      Float,  :required => false
  property :difference,  Float,  :required => false

  has n, :sites,          :model => "Voeis::Site", :through => Resource
  has n, :sensor_values,  :model => "Voeis::SensorValue", :through => Resource
  has n, :variables,      :model => "Voeis::Variable", :through => Resource
  #has n, :methods, :model => "Method", :through => Resource

  # This method allows us to do things like
  #    yogo_project_path(@project)
  # Instead of having to put @project.id
  def to_param
    self.name
  end
end