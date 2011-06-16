require 'active_model/attribute_methods'
require 'active_support/concern'
require 'cassandra'

require 'cassandra_mapper/serialization'

module CassandraMapper
  module Ordering
    module Query
      extend ActiveSupport::Concern

      module ClassMethods
        # Valid query attributes:
        #   :start    => start point in ordering
        #   :finish   => finish point in ordering
        #   :count    => max number of unique ordered-value groups to return documents from
        #   :reversed => reverse the ordering
        #   :consistency => Cassandra consistency requirements for the query
        def ordered_by(order_field, group_by_val="\0", query={})
          order_name = order_field.to_s
          if orderings.keys.include?(order_name)
            query = query.dup
            keys_only = query.delete(:keys_only)

            # identify the family and row to query
            column_family = "#{self.model_name.collection}_by_#{order_name}"
            row = serialize_value(group_by_val)
            # preprocess the query start and finish values (if provided)
            query[:start]  = serialize_value(query[:start])   if query.has_key? :start
            query[:finish] = serialize_value(query[:finish])  if query.has_key? :finish

            # retreive the matching document keys in their supercolumn groupings
            super_columns = CassandraMapper.client.get(column_family, row, query)

            # if this is a reverse query, then reverse all the columns within a supercolumn
            key_groups = super_columns.values.map  do |sc|
              if query[:reversed]
                then sc.keys.reverse
                else sc.keys
              end
            end

            # return the documents / keys (depending on the :keys_only option)
            doc_keys = key_groups.flatten
            if keys_only
              then doc_keys
              else (doc_keys.map {|key| self.find(key)}).delete_if(&:nil?)
            end

          else raise NotImplementedError,
                 "The field #{order_name} of #{self.name} is not ordered."
          end

        rescue CassandraThrift::NotFoundException
          []
        end

        def find_by(order_field, order_val, group_by_val="\0", options={})
          order_name = order_field.to_s
          if orderings.keys.include?(order_name)
            options = options.dup
            keys_only = options.delete(:keys_only)

            # ask for one more than our caller so we can provide a continuation index
            count = options[:count] += 1  if options.has_key? :count
            # preprocess the query start and finish values (if provided)
            options[:start]  = serialize_value(options[:start])   if options.has_key? :start
            options[:finish] = serialize_value(options[:finish])  if options.has_key? :finish
            # retreive the keys for all documents with a matching ordered value
            column_family = "#{self.model_name.collection}_by_#{order_name}"
            row     = serialize_value(group_by_val)
            sup_col = serialize_value(order_val)
            cols    = CassandraMapper.client.get(column_family, row, sup_col, options)

            # return the matching documents
            if keys_only
              then cols.keys
              else (cols.keys.map {|key| self.find(key)}).delete_if(&:nil?)
            end
          end

        rescue CassandraThrift::NotFoundException
          []
        end

        def find_by_index(indexed_field, value, options={})
          cf = self.class.column_family
          idx_expr = {:column_name => indexed_field.to_s,
                      :value       => serialize_value(value),
                      :comparison  => "eq"}
          CassandraMapper.client.get_indexed_slices(cf, [idx_expr], options)

          # return the matching documents
          cols.keys.map {|key| self.load(key)}
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
