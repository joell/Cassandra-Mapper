require 'active_support/concern'

require 'cassandra_mapper/versioning/persistence'
require 'cassandra_mapper/versioning/properties'
require 'cassandra_mapper/versioning/retrieval'

module CassandraMapper
  module Versioning
    extend ActiveSupport::Concern

    included do
      extend  Properties
      include Persistence
      include Retrieval

      private
      ZOMBIE_FAMILY  = "zombie_#{self.model_name.collection}"
      ACTIVES_FAMILY = "#{self.model_name.collection}_by_last_update"
    end
  end
end
