require 'cassandra'

require 'cassandra_mapper/document'

module CassandraMapper
  class << self
    def client
      Thread.current[:cassandra_mapper_client] ||= Cassandra.new(*client_config)
    end

    def client_config
      # TODO: Actually read a YAML file to get these values or something
      server   = '127.0.0.1:9160'
      keyspace = 'CassandraMapper_Dev'
      options  = {:timeout => 10}
      [keyspace, server, options]
    end
  end
end
