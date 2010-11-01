# ODMVersion
#
# DThe ODM Version table has a single record that records the version of the ODM database.  This
# table must contain a valid ODM version number.  This table will be pre-populated and should
# not be edited.
#
class His::ODMVersion 
  include DataMapper::Resource
  def self.default_repository_name
    :his
  end
  storage_names[:his] = "odm_versions"

  property :version_number, String, :required => true, :key =>true
end
