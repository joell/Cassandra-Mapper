require 'active_model/naming'
require 'active_support/concern'

require 'cassandra_mapper/attribute_methods'
require 'cassandra_mapper/conversion'
require 'cassandra_mapper/embedded_document'
require 'cassandra_mapper/ordering'
require 'cassandra_mapper/persistence'
require 'cassandra_mapper/properties'
require 'cassandra_mapper/versioning'

module CassandraMapper
  module Document
    extend ActiveSupport::Concern

    included do
      extend  ActiveModel::Naming
      include CassandraMapper::Persistence
      extend  CassandraMapper::Properties
      include CassandraMapper::AttributeMethods
      include CassandraMapper::Conversion
      include CassandraMapper::Ordering
    end
  end
end
