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
          when Integer                then Cassandra::Long.new(v).to_s
          when Float                  then [v].pack('G')
          when String                 then v
          when TrueClass, FalseClass  then v ? "\1" : "\0"
          when Time, Date             then serialize_value(time_to_int(v))
          else
            v.to_json.tap do |json|
              raise ArgumentError  unless JSON.parse(json) == v
            end
        end
      end

      def deserialize_value(bytes, type)
        case type.to_s.to_sym
          when :Integer  then Cassandra::Long.new(bytes).to_i
          when :Float    then bytes.unpack('G')[0]
          when :String   then bytes
          when :Boolean  then not bytes == "\0"
          when :Time, :Date, :DateTime
            then int_to_time(deserialize_value(bytes, Integer), type)
          else                JSON.parse(bytes)
        end
      end

      def time_to_int(t)
        case t
          when Time      then t.to_i
          when Date      then t.to_time.to_i
        end
      end

      def int_to_time(t, type)
        case type.to_s.to_sym
          when :Time      then Time.at(t)
          when :Date      then int_to_time(t, Time).to_date
          when :DateTime  then int_to_time(t, Time).to_datetime
        end
      end
    end
  end
end
