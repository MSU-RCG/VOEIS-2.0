class Voeis::LocalProjectionCV
  include DataMapper::Resource
  include Yogo::Versioned::DataMapper::Resource

  property :id,         Serial
  property :term,       String, :required => true, :index => true, :length => 512
  property :definition, Text

  yogo_versioned

  has n, :sites,             :model => "Voeis::Site",         :through => Resource, :required=>false
end