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

      define_model_callbacks :save
    end

    module ClassMethods
      def load(key, options = {})
        column_family = self.model_name.collection
        columns = CassandraMapper.client.get(column_family, key, options)
        self.new(CassandraMapper::Serialization.deserialize_attributes(columns, self.properties)).tap do |doc|
          doc.key = key
          doc.instance_variable_set(:@new, false)
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

      def save(options = {})
        # TODO: If updating (i.e., @new is false), use Dirty tagging to only
        #   upload columns that changed
        _run_save_callbacks do
          self.key ||= SimpleUUID::UUID.new.to_guid
          column_family = self.class.model_name.collection
          attrs = CassandraMapper::Serialization.serialize_attributes(self.attributes)
          CassandraMapper.client.insert(column_family, self.key, attrs, options)

          @is_new = false
        end
        true
      end
    end
  end
end
