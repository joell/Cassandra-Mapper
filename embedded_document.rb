require 'active_model/naming'
require 'active_support/concern'
require 'json'

require 'cassandra_mapper/attribute_methods'
require 'cassandra_mapper/embedded_document/dirty'
require 'cassandra_mapper/properties'
require 'cassandra_mapper/serialization'

module CassandraMapper
  module EmbeddedDocument
    extend ActiveSupport::Concern
    include ActiveModel::Naming

    included do
      extend  CassandraMapper::Properties
      include CassandraMapper::AttributeMethods
      include CassandraMapper::EmbeddedDocument::Dirty

      attr_accessor :_parent_document
    end

    module ClassMethods
      def json_create(object)
        attrs = object['attributes'].each_with_object({})  do |(k,v), h|
          type = properties[k][:type]
          h[k] = case
            when type <= Time, type <= Date then
              CassandraMapper::Serialization.int_to_time(v, type)
            else v
          end
        end
        new(attrs).tap do |doc|
          doc.changed_attributes.clear
        end
      end

      def load(str)
        JSON.parse(str).tap do |doc|
          raise TypeError, "JSON does not parse to a #{self.name}"  unless doc.is_a? self
        end
      end
    end

    module InstanceMethods
      def ==(other)
        other.instance_of?(self.class) &&
          other.instance_variable_get(:@attributes) == attributes
      end

      def save_to_bytes(*args)
        attrs = attributes.each_with_object({})  do |(k,v), h|
          h[k] = case v
            when Time, Date  then CassandraMapper::Serialization.time_to_int(v)
            else v
          end
        end

        {
          JSON.create_id => self.class.name,
          :attributes    => attrs
        }.to_json(*args).tap  { changed_attributes.clear }
      end

      alias_method :to_json, :save_to_bytes
    end
  end
end
