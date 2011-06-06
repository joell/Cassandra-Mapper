require 'active_support/concern'

require 'cassandra_mapper/cassandra'

module CassandraMapper
  module Versioning
    module Persistence
      extend ActiveSupport::Concern

      LONG_ZERO = Cassandra::Long.new(0).to_s

      included do
        before_save    :save_old
        before_destroy :save_old
        after_save     :reactivate
        after_destroy  :deactivate

        property :_num_versions, Integer, :default => 0
      end

      module InstanceMethods
        # execute a block that saves the document without the changes being versioned
        def without_versioning
          @without_versioning = true
          result = yield
          @without_versioning = false
          result
        end

        def permanently_destroy
          without_versioning { destroy }  # destroy the document

          # destroy the zombies
          CassandraMapper.client.get(ZOMBIE_FAMILY, key).values.each  do |zombie_key|
            CassandraMapper.client.remove(self.class.column_family, zombie_key)
          end
          CassandraMapper.client.remove(ZOMBIE_FAMILY, key)  # destroy the zombie record
        end

        private
        def save_old
          unless @without_versioning || new?
            # save a copy of the old version of the document (a zombie)
            zombie_key = generate_key
            CassandraMapper.client.insert(self.class.column_family, zombie_key,
                                          _raw_columns)

            # add a zombie entry for the new doc mapped to this one's pre-save timestamp
            cols = {LONG_ZERO => version_group,
                    Cassandra::Long.new(timestamp).to_s => zombie_key}
            CassandraMapper.client.insert(ZOMBIE_FAMILY, key, cols)
            self._num_versions += 1

            # remove the last zombie if we're at max
            if _num_versions > self.class.max_versions
              # get the entry for the oldest zombie
              oldest = CassandraMapper.client.get(ZOMBIE_FAMILY, key,
                                                  :start => 1, :count => 1)
              (oldest_col, oldest_key) = oldest.first
              # remove the zombie from our record
              CassandraMapper.client.remove(ZOMBIE_FAMILY, key, oldest_col)
              # destroy the zombie
              CassandraMapper.client.remove(self.class.column_family, oldest_key)

              self._num_versions = self.class.max_versions
            end

            # save the old timestamp for when we update the "active" record post-save
            @_old_timestamp = timestamp
          end
        end

        # Update this doc's timestamp entry from the `actives' family after
        # it was saved and we have the new timestamp.
        def reactivate
          unless @without_versioning
            # remove the old timestamp entry
            deactivate(@_old_timestamp)  unless new?
            # write a new timestamp entry
            active_since = Cassandra::Long.new(timestamp).to_s
            CassandraMapper.client.insert(ACTIVES_FAMILY, version_group,
                                          {active_since => {key => ""}})
          end
        end

        # Remove this doc's timestamp entry from the `actives' family.
        def deactivate(stamp = timestamp)
          active_since = Cassandra::Long.new(stamp).to_s
          CassandraMapper.client.remove(ACTIVES_FAMILY, version_group, active_since, key)
        end

        def version_group
          field = self.class.version_group_field
          field ? serialize_value(attributes[field]) : "\0"
        end

        def serialize_value(*args)
          CassandraMapper::Serialization.serialize_value(*args)
        end
      end
    end
  end
end
