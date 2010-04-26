module DataMapper
  module Model
    ##
    # Does a search
    #
    # @example
    #   search("me")
    #
    # @param [String] value
    # @param [Hash] options 
    #
    # @return [String] Searches over all of the fields with a like
    #
    # @author Yogo Team
    #
    # @api public
    def search(value, options = {})
      # Datamapper doesn't perform an actual query until the query object is looked at.
      # So we create a bunch individual query objects, and 'or' them together.
      # only 1 query is performed in the end.
      queries = []
      properties.each do |prop|
        if prop.type == String
          queries << all( options.merge(prop.name.like => "%#{value}%") )
        end
      end

      query = []
      if !queries.empty?
        query = queries.first
        queries[1..-1].each{|q| query = query | q } unless queries.length < 1
      end
      
      return query
    end
  end
  
  class Collection
    
    ##
    # Does a search
    #
    # @example
    #   search("me")
    #
    # @param [String] value
    # @param [Hash] options 
    #
    # @return [String] Searches over all of the fields with a like
    #
    # @author Yogo Team
    #
    # @api public
    def search(value, options = {})
      # Datamapper doesn't perform an actual query until the query object is looked at.
      # So we create a bunch individual query objects, and 'or' them together.
      # only 1 query is performed in the end.
      queries = []
      properties.each do |prop|
        if prop.type == String
          queries << all( options.merge(prop.name.like => "%#{value}%") )
        end
      end
      
      query = queries.first
      queries[1..-1].each{|q| query = query | q }
      
      return query
    end
  end
end