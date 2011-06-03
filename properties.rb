require 'active_support/core_ext/hash/indifferent_access'

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
  end
end

# a Boolean "type" for properties
unless defined?(Boolean)
  module ::Boolean; end
end
