# require 'datamapper/authlogic/compatability'
class User
  include DataMapper::Resource
  # include DataMapper::Authlogic::Compatability
  include SentientUser

  attr_accessor :password, :password_confirmation

  property :id,                 DataMapper::Types::Serial
  property :login,              String, :required => true, :index => true, :unique => true
  # property :email,              String, :required => true, :length => 256
  # property :first_name,         String, :required => true, :length => 50
  # property :last_name,          String, :required => true, :length => 50  

  # TODO: Make sure a length of 128 is long enough for various encryption algorithms.
  property :crypted_password,     BCryptHash, :required => true,  :length => 128
  # property :persistence_token,    String, :required => true,  :length => 128, :index => true

  if Yogo::Setting[:allow_api_key] == true
    property :single_access_token,  String, :required => false, :length => 128, :index => true
  end

  property :login_count,        Integer, :required => true, :default => 0
  property :failed_login_count, Integer, :required => true, :default => 0

  property :last_request_at,    DateTime
  property :last_login_at,      DateTime
  property :current_login_at,   DateTime
  
  # Long enough for an ipv6 address.
  property :last_login_ip,      String, :length => 36
  property :current_login_ip,   String, :length => 36

  property :created_at, DateTime
  property :created_on, Date

  property :updated_at, DateTime
  property :updated_on, Date

  has n, :groups, :through => Resource

  validates_is_confirmed :password

  # acts_as_authentic do |config| 
  #   config.instance_eval do
  #     validates_uniqueness_of_email_field_options :scope => :id
  #     validate_login_field false
  #   end
  # end
  # 
  ##
  # Finds a user by their login.
  # 
  # @example
  #   User.find_by_login('lamb') # Returns a user
  # 
  # @param [String]
  #   The login to look for.
  # 
  # @return [User or nil]
  #   Returns the user if found, or nil if no user was found
  # 
  # @author Robbie Lamb
  # 
  # @api public
  def self.find_by_login(login)
    self.first(:login => login)
  end
  
  ##
  # Compatability method for rails' route generation helpers
  #
  # @example
  #   @project.to_param # returns the ID as a string
  # 
  # @return [String] the object id as url param
  #
  # @author Yogo Team
  #
  # @api public
  def to_param
    self.id.to_s
  end
  
  ##
  # Returns the user first and last name in one string
  # 
  # @example
  #   <%= current_user.name %>
  # 
  # @returns [String]
  # 
  # @author lamb
  # 
  # @api public
  def name
    "#{first_name} #{last_name}"
  end
  
  
  ##
  # Password setter
  # 
  # @example
  #   current_user.password = 'a password'
  # 
  # @param [String] pass
  #   A password to set. Note that password_confirmation also needs to be set.
  # 
  # @return [String] the string that was passed in
  # 
  # @api public
  def password=(pass)
    @password = pass
    self.crypted_password = pass
  end
  
  ##
  # Check if the user belongs to a given group
  # 
  # @example
  #   current_user.has_group?(:group_name)
  # 
  # @param [Symbol or String] group
  # 
  # @return [TrueClass or FalseClass]
  #   True if the user belongs to the group or False if the user doesn't belong to the group
  # 
  # @api public
  def has_group?(group_name, project = nil)
    @_user_groups ||= Group.all(:project => project, :users => self).collect(&:name)
    @_user_groups.include?(group_name.to_s)
  end
  
end