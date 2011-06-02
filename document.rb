require 'active_support/concern'
require 'cassandra_mapper/properties'
require 'cassandra_mapper/attribute_methods'

module CassandraMapper
  module Document
    extend ActiveSupport::Concern

    included do
      extend  CassandraMapper::Properties
      include CassandraMapper::AttributeMethods
    end
  end
end
