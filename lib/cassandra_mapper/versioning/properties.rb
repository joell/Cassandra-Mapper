require 'active_support/concern'

module CassandraMapper
  module Versioning
    module Properties
      extend ActiveSupport::Concern

      def inherited(subclass)
        super
        sc_obl_cbs = subclass.instance_variable_get(:@_obliterate_callbacks) || []
        subclass.instance_variable_set(:@_obliterate_callbacks,
                                       sc_obl_cbs + _obliterate_callbacks)
        subclass.versioning_group_by(version_group_field)
      end

      def max_versions(n=5)
        @max_versions ||= n
      end

      # WARNING: Whatever field you choose for this DON'T LET IT CHANGE after
      #   your first save!!
      def versioning_group_by(field)
        unless properties.has_key?(field)
          raise ArgumentError, "Versioning group field must be a document property."
        end
        @version_group_field = field
      end

      attr_reader :version_group_field

      def before_obliterate(*methods)
        @_obliterate_callbacks ||= []
        @_obliterate_callbacks += methods
      end

      def _obliterate_callbacks
        @_obliterate_callbacks ||= []
      end
    end
  end
end
