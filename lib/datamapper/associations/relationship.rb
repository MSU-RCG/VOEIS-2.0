module DataMapper
  module Associations
    class Relationship
      
      # Position
      # @example property.position
      # @return [Integer]
      # @api public
      attr_accessor :position

      # Human readable display name
      # @example property.display_name
      # @return [String]
      # @api public
      attr_accessor :display_name

      # Prefix
      # @example property.prefix
      # @return [String]
      # @api public
      attr_accessor :prefix
      
      # Original Initialize
      # @example orginal_initialize
      # @return 
      # @api public
      alias original_initialize initialize
      
      def initialize(name, child_model, parent_model, options = {})

        pos = options.delete(:position)
        self.position = pos.nil? ? nil : pos.to_i

        prefix = options.delete(:prefix)
        self.prefix = prefix.nil?  ? "" : prefix

        self.display_name = name.to_s.sub("#{self.prefix}", "")

        # name = (self.prefix + display_name).to_sym

        # puts self.class
        # puts name
        # puts child_model
        # puts parent_model
        # puts display_name

        original_initialize(name, child_model, parent_model, options)
      end
    end
  end
end