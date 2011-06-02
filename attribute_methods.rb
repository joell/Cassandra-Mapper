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
      def attributes
        @attributes
      end

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

      def initialize(attrs={})
        super
        @attributes = self.class.properties.inject({})  do |as, prop|
            if default = prop[1][:options][:default]
              as[prop[0]] = default
            end
            as
          end.with_indifferent_access
        self.attributes = attrs
      end

      def method_missing(method, *args, &block)
        self.class.define_attribute_methods
        super
      end

      def respond_to?(*args)
        self.class.define_attribute_methods
        super
      end
    end
  end
end
