# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cassandra-mapper}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Joel Lathrop}]
  s.date = %q{2011-06-09}
  s.description = %q{A document mapper for Cassandra.}
  s.email = %q{}
  s.extra_rdoc_files = [%q{README.md}, %q{lib/cassandra_mapper.rb}, %q{lib/cassandra_mapper/attribute_methods.rb}, %q{lib/cassandra_mapper/attribute_methods/associate_embeds.rb}, %q{lib/cassandra_mapper/attribute_methods/dirty.rb}, %q{lib/cassandra_mapper/attribute_methods/read.rb}, %q{lib/cassandra_mapper/attribute_methods/write.rb}, %q{lib/cassandra_mapper/attribute_methods/write_casts.rb}, %q{lib/cassandra_mapper/cassandra.rb}, %q{lib/cassandra_mapper/conversion.rb}, %q{lib/cassandra_mapper/document.rb}, %q{lib/cassandra_mapper/embedded_document.rb}, %q{lib/cassandra_mapper/embedded_document/dirty.rb}, %q{lib/cassandra_mapper/many.rb}, %q{lib/cassandra_mapper/ordering.rb}, %q{lib/cassandra_mapper/ordering/persistence.rb}, %q{lib/cassandra_mapper/ordering/properties.rb}, %q{lib/cassandra_mapper/ordering/query.rb}, %q{lib/cassandra_mapper/ordering/validate_properties.rb}, %q{lib/cassandra_mapper/persistence.rb}, %q{lib/cassandra_mapper/properties.rb}, %q{lib/cassandra_mapper/railtie.rb}, %q{lib/cassandra_mapper/serialization.rb}, %q{lib/cassandra_mapper/versioning.rb}, %q{lib/cassandra_mapper/versioning/persistence.rb}, %q{lib/cassandra_mapper/versioning/properties.rb}, %q{lib/cassandra_mapper/versioning/retrieval.rb}]
  s.files = [%q{README.md}, %q{Rakefile}, %q{lib/cassandra_mapper.rb}, %q{lib/cassandra_mapper/attribute_methods.rb}, %q{lib/cassandra_mapper/attribute_methods/associate_embeds.rb}, %q{lib/cassandra_mapper/attribute_methods/dirty.rb}, %q{lib/cassandra_mapper/attribute_methods/read.rb}, %q{lib/cassandra_mapper/attribute_methods/write.rb}, %q{lib/cassandra_mapper/attribute_methods/write_casts.rb}, %q{lib/cassandra_mapper/cassandra.rb}, %q{lib/cassandra_mapper/conversion.rb}, %q{lib/cassandra_mapper/document.rb}, %q{lib/cassandra_mapper/embedded_document.rb}, %q{lib/cassandra_mapper/embedded_document/dirty.rb}, %q{lib/cassandra_mapper/many.rb}, %q{lib/cassandra_mapper/ordering.rb}, %q{lib/cassandra_mapper/ordering/persistence.rb}, %q{lib/cassandra_mapper/ordering/properties.rb}, %q{lib/cassandra_mapper/ordering/query.rb}, %q{lib/cassandra_mapper/ordering/validate_properties.rb}, %q{lib/cassandra_mapper/persistence.rb}, %q{lib/cassandra_mapper/properties.rb}, %q{lib/cassandra_mapper/railtie.rb}, %q{lib/cassandra_mapper/serialization.rb}, %q{lib/cassandra_mapper/versioning.rb}, %q{lib/cassandra_mapper/versioning/persistence.rb}, %q{lib/cassandra_mapper/versioning/properties.rb}, %q{lib/cassandra_mapper/versioning/retrieval.rb}, %q{cassandra-mapper.gemspec}]
  s.homepage = %q{http://github.com/joell/Cassandra-Mapper}
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{Cassandra-mapper}, %q{--main}, %q{README.md}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{cassandra-mapper}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{A document mapper for Cassandra.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cassandra>, [">= 0.11"])
      s.add_runtime_dependency(%q<activemodel>, ["~> 3.0.0"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_runtime_dependency(%q<simple_uuid>, [">= 0.1.2"])
    else
      s.add_dependency(%q<cassandra>, [">= 0.11"])
      s.add_dependency(%q<activemodel>, ["~> 3.0.0"])
      s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_dependency(%q<simple_uuid>, [">= 0.1.2"])
    end
  else
    s.add_dependency(%q<cassandra>, [">= 0.11"])
    s.add_dependency(%q<activemodel>, ["~> 3.0.0"])
    s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
    s.add_dependency(%q<simple_uuid>, [">= 0.1.2"])
  end
end
