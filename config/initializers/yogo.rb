
##
# Check to make sure the asset directory exists and make it if it doesn't
# TODO: If the user changes the setting we should make sure that directory exists...but we don't.
if ! File.directory?(File.join(Rails.root, Setting['asset_directory']))
  FileUtils.mkdir_p(File.join(Rails.root, Setting['asset_directory']))
end

# Custom extensions for Yogo
require 'exceptions'

# Load the Application Version
load Rails.root / "VERSION"

# Create the system administrator user
User.create(:login => 'yogo', :email => "none", :first_name => "System",
            :last_name => "Administrator", :admin => true,
            :password => 'change me', :password_confirmation => 'change me')


# VOEIS Specific Role Initialization
Role.first_or_create(:name => "Principal Investigator", :description => "Principal Investigators create projects to pursue research goals.")
Role.first_or_create(:name => "Field Technician",       :description => "Field Technicians manage field activities.")
Role.first_or_create(:name => "Laboratory Technician",  :description => "Lab Technicians manage lab activities.")
Role.first_or_create(:name => "Data Manager",           :description => "Data Managers manage all the data for a project.")
Role.first_or_create(:name => "Member",                 :description => "General members of projects.")

# Load/create users (from a file?)
User.create(:login => 'test', :email => "test@user.org", :first_name => "Test", :last_name => "User",
            :password => "VOEISdude", :password_confirmation => "VOEISdude")

# Load/create units
Unit.first_or_create(:units_name =>"Meters",
                     :units_type =>"Distance",
                     :units_abbreviation => "m")
Unit.first_or_create(:units_name =>"Degrees Celsius",
                     :units_type =>"Temperature",
                     :units_abbreviation => "C")
# Load/create variables
Variable.first_or_create(:variable_name => "Water Depth",
                         :variable_code => "H2O Dpth",
                         :time_support => 1.0,
                         :variable_units_id => 1)
Variable.first_or_create(:variable_name => "Water Height",
                         :variable_code => "H2O Hght",
                         :time_support => 1.0,
                          :variable_units_id => 1)
Variable.first_or_create(:variable_name => "Air Temperature",
                         :variable_code => "AirTemp",
                         :time_support => 1.0,
                          :variable_units_id => 2)
# Load/create sites
Site.first_or_create(:code =>"BLU_MSU",
                      :name => "Blunderville",
                      :lat => 45.2,
                      :long => -111.4,
                      :state => "Montana")
Site.first_or_create(:code =>"LOS_MSU",
                      :name => "Losertown",
                      :lat => 45.8,
                      :long => -111.32,
                      :state => "Montana")
