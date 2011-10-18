# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: Role.rb
# Roles for projects and users. A Project will have Roles, and users will belong to Roles
require 'dm-core'
require 'dm-types/yaml'

class Role
  include DataMapper::Resource
  include Facet::DataMapper::Resource

  #because this is depricated we are doing this AWESOME aliasing
  alias :update_attributes :update
  property :id, Serial
  property :name, String, :required => true, :unique => true
  property :description, Text
  property :actions, Yaml, :default => [].to_yaml

  has n, :memberships
  has n, :projects, :through => :memberships
  has n, :users, :through => :memberships

  is :list

  def self.permission_sources
    [Project, Membership, Role, User,
      Voeis::DataStream,
      Voeis::DataStreamColumn,
      Voeis::MetaTag,
      Voeis::SensorType,
      Voeis::SensorValue,
      Voeis::Site,
      Voeis::Unit,
      Voeis::Variable,
      Voeis::DataValue,
      Voeis::Sample,
      Voeis::SampleMaterial,
      Voeis::LabMethod,
      Voeis::MetaTag,
      Voeis::VerticalDatumCV,
      Voeis::SpatialReference,
      Voeis::FieldMethod,
      Voeis::GeneralCategoryCV,
      Voeis::Lab,
      Voeis::LoggerTypeCV,
      Voeis::QualityControlLevel,
      Voeis::SampleMediumCV,
      Voeis::SensorTypeCV,
      Voeis::SiteDataCatalog,
      Voeis::Source,
      Voeis::SpatialOffset,
      Voeis::SpatialOffsetType,
      Voeis::SpeciationCV,
      Voeis::ValueTypeCV,
      Voeis::VariableNameCV,
      Voeis::Equipment,
      Voeis::DataSet,
      Voeis::Visit,
      Voeis::Campaign]
  end

  def self.available_permissions
    @_availaible_permissions ||= permission_sources.map {|ps| ps.to_permissions}.flatten
  end

  def self.available_permissions_by_source
    source_hash = Hash.new
    permission_sources.each { |ps| source_hash[ps.name] = ps.to_permissions }
    source_hash
  end

  def has_permission?(permission)
    actions.include?(permission)
  end

end
