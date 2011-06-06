require 'active_support/core_ext/hash/keys'
require 'cassandra'
require 'erb'
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
      Thread.current[:cassandra_mapper_client] ||= Cassandra.new(*client_config)
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
end
