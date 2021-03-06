# sysdiagrams
#
# Doesn't appear to be associated with any other tables
#
class His::SysDiagram 
  include DataMapper::Resource
  def self.default_repository_name
    :his
  end
  storage_names[:his] = "sys_diagrams"

  property :name,         String,   :required => true, :unique => true
  property :principal_id, Integer,  :required => true, :unique => true
  property :diagram_id,   Serial,   :required => true,                  :key => true
  property :version,      Integer
  property :definition,   Boolean
end
