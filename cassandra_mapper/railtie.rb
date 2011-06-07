require 'rails/railtie'
require 'cassandra_mapper/cassandra'

module CassandraMapper
  class Railtie < Rails::Railtie
    initializer "cassandra.configure_rails_initialization" do
      default_config_path = Rails.root.join('config', 'cassandra.yml')
      if File.exists?(default_config_path)
        CassandraMapper.load_configuration(default_config_path)
      end
    end
  end
end
