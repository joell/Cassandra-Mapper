require 'active_support/concern'

module CassandraMapper
  module Ordering
    module ValidateProperties
      extend ActiveSupport::Concern

      ORDERABLE_TYPES = [Integer,Float,String,TrueClass,FalseClass,Time,Date]

      module InstanceMethods
        def initialize(*args)
          props = self.class.properties
          self.class.orderings.each  do |(ord_field, opts)|
            case
              when ord_field != "key" && !props.has_key?(ord_field)
                then raise SyntaxError, "#{ord_field} is not a document property."

              when ord_field != "key" && !(ORDERABLE_TYPES.any? {|ty| props[ord_field][:type] <= ty})
                then raise TypeError, "#{type} is not a primitive, orderable type."

              #   Validate that all ordered properties groupings are on a different,
              # valid property.
              when opts.has_key?(:group_by)  then
                begin
                  group_field = opts[:group_by]
                  if not props.has_key?(group_field) || group_field == ord_field
                    raise ArgumentError,
                      "The ordered property #{ord_field} is grouped by an invalid field."

                  elsif not ORDERABLE_TYPES.any? {|ty| props[group_field][:type] <= ty}
                    raise TypeError, "#{type} is not a primitive, orderable type."
                  end
                end
            end
          end

          super
        end
      end
    end
  end
end
