require 'active_model'
require 'active_support/concern'
require 'cassandra'
require 'simple_uuid'

require 'cassandra_mapper/cassandra'
require 'cassandra_mapper/serialization'

module CassandraMapper
  module Persistence
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks

      define_model_callbacks :save, :destroy

      attr_reader :_raw_columns
      attr_reader :timestamp
    end

    module ClassMethods
      def load(key, options = {})
        column_family = model_name.collection
        _raw_columns = CassandraMapper.client.get(column_family, key, options)
        new(CassandraMapper::Serialization.deserialize_attributes(_raw_columns, properties)).tap do |doc|
          last_updated = _raw_columns.timestamps.values.max
          doc.instance_variable_set(:@key, key)
          doc.instance_variable_set(:@is_new, false)
          doc.instance_variable_set(:@timestamp, last_updated)
          doc.instance_variable_set(:@_raw_columns, _raw_columns)
          doc.changed_attributes.clear
        end
      end

      def find(key, *args)
        self.load(key, *args) rescue nil
      end
    end

    module InstanceMethods
      def initialize(*args)
        super
        @is_new = true
      end

      def new?
        @is_new
      end

      def key
        @key ||= SimpleUUID::UUID.new.to_guid
      end

      def save(options = {})
        written = false
        was_success = _run_save_callbacks  do
          column_family = self.class.model_name.collection
          @_raw_columns = CassandraMapper::Serialization.serialize_attributes(attributes)
          changed_columns = @_raw_columns.dup
          changed_columns.select! { |k,v| changed_attributes.include?(k) }  unless @is_new

          now = Time.stamp
          options[:timestamp] = now
          CassandraMapper.client.insert(column_family, key, changed_columns, options)

          @timestamp = now
          written = true
        end

        @is_new = !written
        was_success
      end

      def destroy(options={})
        _run_destroy_callbacks  do
          begin
            column_family = self.class.model_name.collection
            CassandraMapper.client.remove(column_family, key, options)  unless new?
            freeze
            true
          rescue
            false
          end
        end
      end
    end
  end
end
