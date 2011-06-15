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

      property :version, Integer, :default => 1

      private
      ZOMBIE_FAMILY  ||= "zombie_#{self.model_name.collection}"
      ACTIVES_FAMILY ||= "#{self.model_name.collection}_by_last_update"
    end
  end
end
