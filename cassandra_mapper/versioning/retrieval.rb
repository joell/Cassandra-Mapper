require 'active_support/concern'

require 'cassandra_mapper/cassandra'

module CassandraMapper
  module Versioning
    module Retrieval
      extend ActiveSupport::Concern

      module InstanceMethods
        def old_versions
          if _num_versions > 0
            # get the zombie keys from newest to oldest
            zombie_keys = CassandraMapper.client.get(ZOMBIE_FAMILY, key,
                            :reversed => true, :finish => 1,
                            :count => self.class.max_versions).values
            zombie_keys.map  { |key| self.class.load(key) }
          else
            []
          end
        end
      end
    end
  end
end
