require 'active_support/concern'

require 'cassandra_mapper/ordering/persistence'
require 'cassandra_mapper/ordering/query'
require 'cassandra_mapper/ordering/validate_properties'

module CassandraMapper
  module Ordering
    extend ActiveSupport::Concern

    included do
      include ValidateProperties
      include Persistence
      include Query
    end

    module ClassMethods
      def orderings
        @orderings ||= (self.properties.select {|_,p| p[:options].has_key?(:ordered)}).keys
      end
    end
  end
end
