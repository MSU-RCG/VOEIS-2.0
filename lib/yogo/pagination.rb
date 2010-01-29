# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: pagination.rb
# 
#
module Yogo
  module Pagination
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
  
    module ClassMethods
      # Returns a subset of objects in the datastore for pagination.
      # 
      # options :page What page to get, default 1
      #         :per_page How many items per page, default 5
      def paginate(options = {})
        page = options.delete(:page) || 1
        per_page = options.delete(:per_page) || 5

        options.merge!({
          :limit => per_page,
          :offset => (page.to_i - 1) * per_page
        })

        all(options)
      end

      # Returns how many pages there are in the database.
      def page_count(options = {})
        per_page = options.delete(:per_page) || 5

        (all(options).count.to_f / per_page).ceil
      end
      
    end
  end
end