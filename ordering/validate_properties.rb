require 'active_support/concern'

module CassandraMapper
  module Ordering
    module ValidateProperties
      extend ActiveSupport::Concern

      ORDERABLE_TYPES = [Integer,Float,String,TrueClass,FalseClass,Time,Date]

      module ClassMethods
        def property(key, type, options={})
          if options.has_key?(:ordered) and not ORDERABLE_TYPES.any? {|ty| type <= ty}
            raise SyntaxError, "#{type} is not a primitive, orderable type."
          end
          super
        end
      end

      module InstanceMethods
        #   Validate that all ordered properties groupings are on a different,
        # valid property.
        def initialize(*args)
          props = self.class.properties
          props.each_pair  do |name, prop|
            if prop[:options].has_key?(:ordered) && prop[:options].has_key?(:group_by)
              group_field = prop[:options][:group_by]
              if not props.has_key?(group_field) || group_field == name
                raise ArgumentError,
                  "The ordered property #{name} is grouped by an invalid field."

              elsif not ORDERABLE_TYPES.any? {|ty| props[group_field][:type] <= ty}
                raise TypeError, "#{type} is not a primitive, orderable type."
              end
            end
          end
          super
        end
      end
    end
  end
end
