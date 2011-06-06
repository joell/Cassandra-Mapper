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

      def column_family
        model_name.collection
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
        @key ||= generate_key
      end

      def save(write_key = key, options = {})
        written = false
        was_success = _run_save_callbacks  do
          @_raw_columns = CassandraMapper::Serialization.serialize_attributes(attributes)
          changed_columns = @_raw_columns.dup
          # if this is a first-time save or an overwrite, we need to write all the columns
          if !@is_new && write_key != key
            changed_columns.select! { |k,v| changed_attributes.include?(k) }
          end

          now = Time.stamp
          options[:timestamp] = now
          CassandraMapper.client.insert(self.class.column_family, write_key,
                                        changed_columns, options)
          key = write_key

          @timestamp = now
          written = true
        end

        @is_new = !written
        was_success
      end

      def destroy(options={})
        _run_destroy_callbacks  do
          begin
            cf = self.class.column_family
            CassandraMapper.client.remove(cf, key, options)  unless new?
            freeze
            true
          rescue
            false
          end
        end
      end

      private
      def generate_key
        SimpleUUID::UUID.new.to_guid
      end
    end
  end
end
