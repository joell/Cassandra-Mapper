require 'active_support/concern'

module CassandraMapper
  module EmbeddedDocument
    module Dirty
      extend ActiveSupport::Concern

      included do
        # assigned to a lambda by the root document that notifies it that its 
        #   embed is about to change
        attr_accessor :embed_will_change
      end

      private
      def attribute=(name, value)
        if self.class.properties.has_key?(name) && @attributes[name] != value
          embed_will_change.call  unless not embed_will_change
        end
        super
      end
    end
  end
end
