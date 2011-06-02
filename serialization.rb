require 'cassandra'
require 'date'
require 'json'

module CassandraMapper
  module Serialization
    class << self
      def serialize_attributes(attrs)
        attrs.each_with_object({})  do |(k,v), h|
          begin
            h[k] = serialize_value(v)
          rescue ArgumentError
            raise ArgumentError, "Unserializable value for #{k}: #{v.inspect}"
          end
        end
      end

      def deserialize_attributes(raw_attrs, props)
        raw_attrs.each_with_object({})  do |(k,v), h|
          h[k] = deserialize_value(v, props[k][:type])
        end
      end

      def serialize_value(v)
        case v
          when Integer   then Cassandra::Long.new(v).to_s
          when Time      then serialize_value(v.to_i)
          when DateTime  then serialize_value(v.to_time)
          when String    then v
          else
            json = v.to_json
            raise ArgumentError  unless JSON.parse(json) == v
            json
        end
      end

      def deserialize_value(bytes, type)
        case type.to_s.to_sym
          when :Integer   then Cassandra::Long.new(bytes).to_i
          when :Time      then Time.at(deserialize_value(bytes, Integer))
          when :DateTime  then deserialize_value(v, Time).to_datetime
          when :String    then bytes
          else                 JSON.parse(bytes)
        end
      end
    end
  end
end
