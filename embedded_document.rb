require 'active_model'
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
      extend  CassandraMapper::Properties
      include CassandraMapper::AttributeMethods
    end

    module ClassMethods
      def json_create(object)
        attrs = object['attributes'].each_with_object({})  do |(k,v), h|
          type = properties[k][:type]
          h[k] = case type.to_s.to_sym
            when :Time, :Date, :DateTime  then
              CassandraMapper::Serialization.int_to_time(v, type)
            else v
          end
        end
        new(attrs)
      end
    end

    module InstanceMethods
      def ==(other)
        other.instance_of?(self.class) &&
          other.instance_variable_get(:@attributes) == attributes
      end

      def to_json(*args)
        attrs = attributes.each_with_object({})  do |(k,v), h|
          h[k] = case v
            when Time, Date  then CassandraMapper::Serialization.time_to_int(v)
            else v
          end
        end

        {
          JSON.create_id => self.class.name,
          :attributes    => attrs
        }.to_json(*args)
      end
    end
  end
end
