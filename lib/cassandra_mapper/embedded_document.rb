require 'active_model/naming'
require 'active_support/concern'
require 'active_model/serialization'

require 'cassandra_mapper/attribute_methods'
require 'cassandra_mapper/embedded_document/dirty'
require 'cassandra_mapper/properties'
require 'cassandra_mapper/serialization'

module CassandraMapper
  module EmbeddedDocument
    extend  ActiveSupport::Concern
    include ActiveModel::Serializers::JSON
    include ActiveModel::Naming

    included do
      extend  CassandraMapper::Properties
      include CassandraMapper::AttributeMethods
      include CassandraMapper::EmbeddedDocument::Dirty

      def attribute=(name, value)
        # if this is an embedded document or `many' attribute that was assigned
        #   a JSON-structured hash, then auto-convert it before assignment
        type = self.class.properties[name][:type]
        if value.class <= Hash
          if type <= CassandraMapper::EmbeddedDocument
            value = type.new(value)
          elsif type.class == Array && type[0] == CassandraMapper::Many
            value = CassandraMapper::Many.new(type[1], type[2], value)
          end
        end

        super(name, value)
      end

      self.include_root_in_json = false  # these are *embedded* documents
    end

    module ClassMethods
      def from_json(json_str)
        self.new.from_json(json_str).tap do |doc|
          doc.changed_attributes.clear
        end
      end

      alias_method :load, :from_json
    end

    module InstanceMethods
      def ==(other)
        other.instance_of?(self.class) &&
          other.instance_variable_get(:@attributes) == attributes
      end

      def as_json(options = nil)
        # do the shallow, one-level conversion
        super(options).tap do |partial|

          # find all properties that are embedded documents
          embed_props = self.class.properties.select  do |k,v|
            type = v[:type]
            type.class == Array && type[0] == CassandraMapper::Many ||
              type <= CassandraMapper::EmbeddedDocument
          end
          # recursively apply the conversion to the embeds
          embed_props.keys.each  do |attr|
            partial[attr] = partial[attr].as_json
          end
        end
      end

      def save_to_bytes
        to_json.tap do
          changed_attributes.clear
        end
      end
    end
  end
end
