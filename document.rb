require 'active_model/naming'
require 'active_support/concern'

require 'cassandra_mapper/attribute_methods'
require 'cassandra_mapper/persistence'
require 'cassandra_mapper/properties'

module CassandraMapper
  module Document
    extend ActiveSupport::Concern

    included do
      extend  ActiveModel::Naming
      include CassandraMapper::Persistence
      extend  CassandraMapper::Properties
      include CassandraMapper::AttributeMethods

      attr_reader :key
    end
  end
end
