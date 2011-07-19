require 'active_support/core_ext/hash/keys'
require 'cassandra'
require 'erb'
require 'thrift'
require 'yaml'

module CassandraMapper
  class << self
    def client
      if not @is_consistency_set
        # Note: Replication defaults are set as metadata in the keyspace schema.
        Cassandra::WRITE_DEFAULTS[:consistency] = Cassandra::Consistency::QUORUM
        Cassandra::READ_DEFAULTS[:consistency]  = Cassandra::Consistency::QUORUM
        @is_consistency_set = true
      end
      Thread.current[:cassandra_mapper_client] ||= CassandraWrapper.new(*client_config)
    end

    def client_config
      @config.values_at(:keyspace, :server, :options)
    end

    def load_configuration(config_file)
      hash = YAML.load(ERB.new(File.read(config_file)).result)
      @config = hash['cassandra_mapper'].symbolize_keys
      @config[:options] ||= {}
      @config[:options].symbolize_keys!
      true
    end
  end

  # NOTE:
  #   There is an as-yet-undiscovered trigger that causes the socket object of
  # the Cassandra Ruby API's Thrift client to be closed.  This then causes the
  # next Cassandra operation to throw an "IOError: closed stream" when a socket
  # write is attempted.
  #   To circumvent this for now, we have resorted to the ugly hack found below.
  # Whenever the client object is requested, we check if the corresponding
  # socket has been closed, and if it has we force a reconnection.
  private
  class CassandraWrapper < Cassandra
    def initialize(keyspace, servers, opts)
      super(keyspace, servers, opts.merge(:thrift_client_class => ThriftClientWrapper))
    end

    def client
      reconnect!  unless connected?
      super
    end

    def connected?
      !@client.nil? && !@client.current_server.nil? && @client.connected?
    end

    private
    class ThriftClientWrapper < ThriftClient
      def connected?
        !@connection.nil? && @connection.transport.open?
      end
    end
  end
end
