require 'active_support/concern'

require 'cassandra_mapper/cassandra'

module CassandraMapper
  module Versioning
    module Persistence
      extend ActiveSupport::Concern

      LONG_ZERO = Cassandra::Long.new(0).to_s

      included do
        before_save    :save_zombie
        before_destroy :save_zombie
        after_save     :post_save_zombie
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
          @without_versioning = true
          destroy

          # destroy the zombies
          CassandraMapper.client.get(ZOMBIE_FAMILY, key).values.each  do |zombie_key|
            CassandraMapper.client.remove(self.class.column_family, zombie_key)
          end
          # destroy the zombie record
          CassandraMapper.client.remove(ZOMBIE_FAMILY, key)
        end

        def save(write_key = key, *args)
          @overwrite_key = write_key  if write_key != key
          super(write_key, *args)
          @overwrite_key = nil
        end

        private
        def save_zombie(*args)
          key = self.key
          without_versioning = @without_versioning
          _raw_columns = self._raw_columns

          # handle the special case of overwriting a different document
          if !without_versioning && @overwrite_key
            cf = self.class.column_family
            _raw_columns = CassandraMapper.client.get(cf, @overwrite_key)
            if _raw_columns.empty?    # does the target document no longer exists?
              without_versioning = true
            else
              key = @overwrite_key
            end
          end

          # if appropriate, retain a copy of the current version of the document
          unless without_versioning || new?
            # save a copy of the old version of the document (a zombie)
            zombie_key = generate_key
            CassandraMapper.client.insert(self.class.column_family, zombie_key,
                                          _raw_columns)

            # add a zombie entry for the new doc mapped to this one's pre-save timestamp
            cols = {LONG_ZERO => version_group,
                    Cassandra::Long.new(timestamp).to_s => zombie_key}
            CassandraMapper.client.insert(ZOMBIE_FAMILY, key, cols)

            if not @overwrite_key
              self._num_versions += 1
              # remove all zombies that exceed our maximum
              if self._num_versions > self.class.max_versions
                surplus = self._num_versions - self.class.max_versions
                # get the entry for the outdated zombies
                outdated = CassandraMapper.client.get(ZOMBIE_FAMILY, key,
                                                      :start => 1, :count => surplus)
                outdated.each do |col, k|
                  # remove the zombie from our record
                  CassandraMapper.client.remove(ZOMBIE_FAMILY, key, col)
                  # destroy the zombie
                  CassandraMapper.client.remove(self.class.column_family, k)
                end

                self._num_versions = self.class.max_versions
              end
            end

            # save the old timestamp for when we update the "active" record post-save
            @_old_timestamp = timestamp
          end
        end

        def post_save_zombie
          # If we overwrote a different document, then we must keep the
          #   old-versions count consistent.
          if @overwrite_key
            # NOTE: We subtract one for the grouping-index column 0.
            self._num_versions = CassandraMapper.client.count_columns(ZOMBIE_FAMILY, key)-1
          end

          # Update this doc's timestamp entry from the `actives' family after
          # it was saved and we have the new timestamp.
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
