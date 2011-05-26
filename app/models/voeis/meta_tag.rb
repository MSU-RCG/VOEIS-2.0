class Voeis::MetaTag
  include DataMapper::Resource
  include Facet::DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource
  
  property :id,       Serial
  #property :name,     String,  :required => true
  property :value,    Text,   :required => true, :required => false
  property :name,     String, :required => true, :length => 512, :index => true
  property :category, String, :required => true, :length => 512, :index => true

  timestamps :at
  yogo_versioned

  has n, :sensor_values, :model => 'Voeis::SensorValue', :through => Resource
  has n, :data_values, :model => 'Voeis::DataValue', :through => Resource
  has n, :variables, :model => 'Voeis::Variable', :through => Resource

end
