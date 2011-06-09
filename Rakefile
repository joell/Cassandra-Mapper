require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('cassandra-mapper', '0.0.1')  do |p|
  p.description          = "A document mapper for Cassandra."
  p.author               = "Joel Lathrop"
  p.url                  = "http://github.com/joell/Cassandra-Mapper"
  p.ignore_pattern       = ["tmp/*"]
  p.runtime_dependencies = ["cassandra >=0.11",
                            "activemodel ~>3.0.0",
                            "activesupport ~>3.0.0",
                            "simple_uuid >=0.1.2"]
end
