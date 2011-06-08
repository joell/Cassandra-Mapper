require 'active_support/concern'
require 'active_model/callbacks'

require 'cassandra_mapper/serialization'

module CassandraMapper
  module Ordering
    module Persistence
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Callbacks

        after_save    :update_orders
        after_destroy :remove_from_ordering

      end

      module InstanceMethods
        def update_orders
          updated = self.class.orderings
          # TODO: BUG: This does not handle changes in the group_by field alone.
          updated &= changed  if not new?
          updated.each  do |order_name|
            # NOTE: We use a super column to avoid conflicts on the ordered value
            group_by_field = self.class.properties[order_name][:options][:group_by]
            column_family = "#{self.class.model_name.collection}_by_#{order_name}"

            # if the old value was non-nil, then its entry must be removed from 
            #   the ordering
            if not new? and old_val = changes[order_name].first
              old_row = "\0"
              if group_by_field
                old_group_val = changes.has_key?(group_by_field) ?
                    changes[group_by_field].first :
                    attributes[group_by_field]
                old_row = serialize_value(old_group_val)
              end
              old_col = serialize_value(old_val)
              CassandraMapper.client.remove(column_family, old_row, old_col, self.key)
            end

            # add our key in the ordering at the location for our new ordered value
            row = group_by_field ? serialize_value(attributes[group_by_field]) : "\0"
            col = serialize_value(attributes[order_name])
            CassandraMapper.client.insert(column_family, row, {col => {self.key => ""}},
                                          :timestamp => timestamp)
            true
          end
        end

        def remove_from_ordering
          self.class.orderings.each  do |order_name|
            # NOTE: We use a super column to avoid conflicts on the ordered value
            group_by = self.class.properties[order_name][:options][:group_by]
            column_family = "#{self.class.model_name.collection}_by_#{order_name}"
            attrs = attributes.merge(changed_attributes)  # discard unwriten changes
            row = group_by ? serialize_value(attrs[group_by]) : "\0"
            col = serialize_value(attrs[order_name])
            CassandraMapper.client.remove(column_family, row, col, self.key)
          end
          true
        end

        private
        def serialize_value(*args)
          CassandraMapper::Serialization.serialize_value(*args)
        end
      end
    end
  end
end
