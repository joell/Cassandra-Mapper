require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'

require 'cassandra_mapper/ordering/persistence'
require 'cassandra_mapper/ordering/properties'
require 'cassandra_mapper/ordering/query'
require 'cassandra_mapper/ordering/validate_properties'

module CassandraMapper
  module Ordering
    extend ActiveSupport::Concern

    included do
      extend  Properties
      include ValidateProperties
      include Persistence
      include Query
    end

    module ClassMethods
      def orderings
        @orderings ||= {}.with_indifferent_access
      end
    end
  end
end
