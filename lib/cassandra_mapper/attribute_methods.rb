require 'active_model'
require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'

require 'cassandra_mapper/attribute_methods/read'
require 'cassandra_mapper/attribute_methods/write'
require 'cassandra_mapper/attribute_methods/write_casts'
require 'cassandra_mapper/attribute_methods/associate_embeds'
require 'cassandra_mapper/attribute_methods/dirty'

module CassandraMapper
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      include Read
      include Write
      include AssociateEmbeds
      include WriteCasts
      include Dirty
      include ActiveModel::MassAssignmentSecurity

      attr_protected :key, :_raw_columns, :timestamp  # defined in Persistence
    end

    module ClassMethods
      def define_attribute_methods
        super(properties.keys)
      end
    end

    module InstanceMethods
      def initialize(attrs={})
        super

        # set up the attributes with any established defaults
        @attributes = {}.with_indifferent_access
        self.attributes = self.class.properties.reduce({})  do |as, prop|
            opts = prop[1][:options]
            as[prop[0]] = opts[:default]  if opts.has_key? :default
            as
          end
        changed_attributes.clear       # default values don't count as "changed"

        # assign the additional supplied attribute values
        self.attributes = attrs
      end

      def freeze
        @attributes.freeze; super
      end

      def method_missing(method, *args, &block)
        self.class.define_attribute_methods
        super
      end

      def respond_to?(*args)
        self.class.define_attribute_methods
        super
      end

      private
      def attributes=(attrs)
        sanitize_for_mass_assignment(attrs).each  do |k,v|
          if respond_to?("#{k}=")
            __send__("#{k}=", v)
          else
            raise ArgumentError, "undefined property: prop = #{k}," +
                                 " class = #{self.class.name}"
          end
        end
      end

      def attributes
        @attributes
      end
    end
  end
end
