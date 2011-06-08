require 'active_model/attribute_methods'
require 'active_support/concern'

require 'cassandra_mapper/serialization'

module CassandraMapper
  module Ordering
    module Query
      extend ActiveSupport::Concern

      module ClassMethods
        # Valid query attributes:
        #   :start    => start point in ordering
        #   :finish   => finish point in ordering
        #   :count    => max number of results
        #   :reversed => reverse the ordering
        #   :consistency => Cassandra consistency requirements for the query
        def ordered_by(order_field, group_by_val="\0", query={})
          order_name = order_field.to_s
          if orderings.include?(order_name)
            # identify the family and row to query
            column_family = "#{self.model_name.collection}_by_#{order_name}"
            row = serialize_value(group_by_val)
            # preprocess the query start and finish values (if provided)
            query[:start]  = serialize_value(query[:start])   if query.has_key? :start
            query[:finish] = serialize_value(query[:finish])  if query.has_key? :finish
            # ask for one more than our caller so we can provide a continuation index
            count = query[:count] += 1  if query.has_key? :count
            # retreive the matching document keys
            super_columns = CassandraMapper.client.get(column_family, row, query)

            # identify the next column to start with in order to continue this query
            next_start = nil
            if super_columns.length == count
              next_start = super_columns.keys.last
              super_columns.delete(next_start)
            end

            # return the matching documents
            order_type = properties[order_field][:type]
            doc_keys = super_columns.values.map(&:keys).flatten
            { :docs       => doc_keys.map  {|key| self.load(key)},
              :next_start => next_start && deserialize_value(next_start, order_type) }

          else raise NotImplementedError,
                 "The field #{order_name} of #{self.name} is not ordered."
          end
        end

        def find_by(order_field, order_val, group_by_val="\0", options={})
          order_name = order_field.to_s
          if orderings.include?(order_name)
            # retreive the keys for all documents with a matching ordered value
            column_family = "#{self.model_name.collection}_by_#{order_name}"
            row     = serialize_value(group_by_val)
            sup_col = serialize_value(order_val)
            cols    = CassandraMapper.client.get(column_family, row, sup_col)

            # return the matching documents
            cols.keys.map {|key| self.load(key)}
          end
        end

        private
        def serialize_value(*args)
          CassandraMapper::Serialization.serialize_value(*args)
        end

        def deserialize_value(*args)
          CassandraMapper::Serialization.deserialize_value(*args)
        end
      end
    end
  end
end
