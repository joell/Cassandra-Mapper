require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/inflector'
require 'cassandra_mapper/many'

module CassandraMapper
  module Properties
    def inherited(subclass)
      super
      subclass.properties.merge!(properties)
    end

    def properties
      @properties ||= {}.with_indifferent_access
    end

    def property(key, type, options={})
      properties[key.to_sym] = {:type => type, :options => options}
    end

    def many(key, options={})
      root_name = key.to_s
      elem_type = (options[:class_name] || root_name.classify).constantize
      options[:default] ||= CassandraMapper::Many.new(elem_type, root_name)
      property(key, [CassandraMapper::Many, elem_type, root_name], options)
    end
  end
end

# a Boolean "type" for properties
unless defined?(Boolean)
  module ::Boolean
    def self.<=(other)
      other == TrueClass || other == FalseClass || other == Boolean
    end
  end
end
