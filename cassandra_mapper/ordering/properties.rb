require 'active_support/core_ext/hash/except'

module CassandraMapper
  module Ordering
    module Properties
      # syntax = :on <ordered field> [, :group_by => <some property field>]
      def ordering(options={})
        orderings[options.fetch(:on, :key)] = options.except(:on)
      end
    end
  end
end
