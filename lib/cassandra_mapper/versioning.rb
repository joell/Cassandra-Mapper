require 'active_support/concern'

require 'cassandra_mapper/versioning/persistence'
require 'cassandra_mapper/versioning/properties'
require 'cassandra_mapper/versioning/retrieval'
require 'cassandra_mapper/versioning/query_timeline'

module CassandraMapper
  module Versioning
    extend ActiveSupport::Concern

    included do
      extend  Properties
      include Persistence
      include Retrieval
      include QueryTimeline

      property :version, Integer, :default => 0
    end

    module ClassMethods
      def zombie_family
        @zombie_family ||= "zombie_#{self.column_family}"
      end

      def actives_family
        @actives_family ||= "#{self.column_family}_by_last_update"
      end
    end
  end
end
