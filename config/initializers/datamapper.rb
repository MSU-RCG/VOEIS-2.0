# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: datamapper.rb
#

# Require custom extensions to datamapper.
require 'datamapper/associations/relationship'
require 'datamapper/paginate'
require 'datamapper/property'
require 'datamapper/model/relationship'
require 'datamapper/search'
require 'datamapper/paginate'
require 'datamapper/factory'
require 'datamapper/dm-userstamp'
require 'datamapper/types/yogo_file'
require 'datamapper/types/yogo_image'
require 'datamapper/types/raw'
require 'yogo/reflection'


module Extlib
  module Assertions

    # Allows for classes to be reloaded.
    # In theory, we might only want to allow this while in development mode.
    #
    # As run the original assert_kind_of and, if an ArgumentError is raised,
    # we double-check that none of the class names match.
    #
    # If they match, we return, assuming that, if the class names match,
    # then the actual type is a match.
    #
    # If there are no class name matches, we raise the original exception.
    def assert_kind_of_with_allow_class_name_matching(name, value, *klasses)
      begin
        assert_kind_of_without_allow_class_name_matching(name, value, *klasses)
      rescue ArgumentError
        klasses.each { |k| return if value.class.name == k.name }
        raise # if we haven't returned, raise the original exception
      end
    end

    alias_method_chain :assert_kind_of, :allow_class_name_matching

  end
end


# Read the configuration from the existing database.yml file
config = Rails.configuration.database_configuration

# Setup the default datamapper repository corresponding to the current rails environment
# unnecessary: rails-datamapper handles this

DataMapper.setup(:default, config[Rails.env])

# Alias :default to :yogo so things work well
DataMapper.setup(:yogo, config["yogo_"+Rails.env])

# Map the datamapper logging to rails logging
DataMapper.logger             = Rails.logger
if Object.const_defined?(:DataObjects)
  DataObjects::Postgres.logger  = Rails.logger if DataObjects.const_defined?(:Postgres)
  DataObjects::Sqlserver.logger = Rails.logger if DataObjects.const_defined?(:Sqlserver)
  DataObjects::Mysql.logger     = Rails.logger if DataObjects.const_defined?(:Mysql)
  DataObjects::Sqlite3.logger    = Rails.logger if DataObjects.const_defined?(:Sqlite3)
end

Project
SchemaBackup
User
Group
DataMapper.auto_migrate! unless DataMapper.repository(:default).storage_exists?(Project.storage_name) &&
                                DataMapper.repository(:default).storage_exists?(SchemaBackup.storage_name) &&
                                DataMapper.repository(:default).storage_exists?(User.storage_name)

admin_g = Group.first_or_create(:name => "Administrator", :description => "VOEIS system administrators.",
                                :admin => true, :project => nil)
Group::AVAILABLE_ACTIONS.each do |action|
  admin_g.add_permission(action)
end
admin_g.save

if admin_g.users.empty?
  admin_g.users.create(:login => 'yogo', :email => "none", :first_name => "System",
                       :last_name => "Administrator", :password => 'change me',
                       :password_confirmation => 'change me')
  admin_g.save
end