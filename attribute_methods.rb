require 'active_model'
require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'

module CassandraMapper
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      attribute_method_suffix ''   # read
      attribute_method_suffix '='  # write

      private
      def attribute(name)
        @attributes[name] if @attributes.include?(name)
      end

      def attribute=(name, value)
        @attributes[name] = value
      end

      public
      include ActiveModel::MassAssignmentSecurity

      attr_protected :key
    end

    module ClassMethods
      def define_attribute_methods
        super(properties.keys)
      end
    end

    module InstanceMethods
      def initialize(attrs={})
        super
        @attributes = self.class.properties.reduce({})  do |as, prop|
            opts = prop[1][:options]
            as[prop[0]] = opts[:default]  if opts.has_key? :default
            as
          end.with_indifferent_access
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
