require 'cassandra'
require 'cassandra_mapper/embedded_document'
require 'cassandra_mapper/many'
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
          when CassandraMapper::Many,
               CassandraMapper::EmbeddedDocument
            then v.save_to_bytes
          else
            v.to_json.tap do |json|
              raise ArgumentError  unless JSON.parse(json) == v
            end
        end
      end

      def deserialize_value(bytes, type)
        case
          when type <= CassandraMapper::Many,
               type <= CassandraMapper::EmbeddedDocument
            then type.load(bytes)
          when type <= Time, type <= Date
            then int_to_time(deserialize_value(bytes, Integer), type)
          when type <= Integer  then Cassandra::Long.new(bytes).to_i
          when type <= Float    then bytes.unpack('G')[0]
          when type <= String   then bytes
          when type <= Boolean  then not bytes == "\0"
          else                       JSON.parse(bytes)
        end
      end

      def time_to_int(t)
        case t
          when Time      then t.to_i
          when Date      then t.to_time.to_i
        end
      end

      def int_to_time(t, type)
        case
          when type <= DateTime  then int_to_time(t, Time).to_datetime
          when type <= Date      then int_to_time(t, Time).to_date
          when type <= Time      then Time.at(t)
        end
      end
    end
  end
end
