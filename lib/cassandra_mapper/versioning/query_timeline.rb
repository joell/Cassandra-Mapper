require 'active_support/concern'
require 'active_support/core_ext/hash/slice'
require 'cassandra'

require 'cassandra_mapper/cassandra'

module CassandraMapper
  module Versioning
    module QueryTimeline
      extend ActiveSupport::Concern

      LONG_ZERO = Cassandra::Long.new(0).to_s

      module ClassMethods
        def versions_active_at_time(time, version_grouping_value, options={})
          coptions = {:key_start => options[:start] || "",
                      :key_count => options[:count] || 20}
          tstamp = Cassandra::Long.new(time.stamp).to_s

          # obtain all matching rows
          raw_matches = CassandraMapper.client.get_indexed_slices(self.column_family,
            [{:column_name => self.version_group_field.to_s,
              :value       => version_grouping_value,
              :comparison  => "eq"},
             {:column_name => "birth_timestamp",
              :value       => tstamp,
              :comparison  => "lte"},
             {:column_name => "death_timestamp",
              :value       => tstamp,
              :comparison  => "gt"}
            ], coptions)

          # convert each match from its raw key and columns to a full document object
          raw_matches.map  do |key, column_array|
            raw_columns = column_array.each_with_object(Cassandra::OrderedHash.new)  do |c,h|
              h.[]=(c.column.name, c.column.value, c.column.timestamp)
            end
            {
              :doc        => self._load_columns(key, raw_columns),
              :active_key => raw_columns["active_version_key"] || key
            }
          end
        end
      end
    end
  end
end
