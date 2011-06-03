require 'active_model/naming'
require 'active_model/serializers/json'
require 'active_support/concern'
require 'json'

require 'cassandra_mapper/attribute_methods'
require 'cassandra_mapper/properties'
require 'cassandra_mapper/serialization'

module CassandraMapper
  module EmbeddedDocument
    extend ActiveSupport::Concern
    include ActiveModel::Naming

    included do
      include ActiveModel::Serializers::JSON

      extend  CassandraMapper::Properties
      include CassandraMapper::AttributeMethods
    end

    module ClassMethods
      def from_json(str)
        new.from_json(str).tap  do |doc|
          doc.changed_attributes.clear
        end
      end
    end

    module InstanceMethods
      def ==(other)
        other.instance_of?(self.class) &&
          other.instance_variable_get(:@attributes) == attributes
      end
    end
  end
end
