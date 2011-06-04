require 'active_support/concern'

require 'cassandra_mapper/many'

module AssociateEmbeds
  extend ActiveSupport::Concern

  private
  def associate_embed(name, embed)
    embed.embed_will_change = lambda { attribute_will_change!(name) }
  end

  def attribute=(name, value)
    super
    case value
      when CassandraMapper::EmbeddedDocument,
           CassandraMapper::Many
        then associate_embed(name, @attributes[name])
    end
  end
end
