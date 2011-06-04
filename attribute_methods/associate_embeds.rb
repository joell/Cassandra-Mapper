require 'active_support/concern'

module AssociateEmbeds
  extend ActiveSupport::Concern

  private
  def attribute=(name, value)
    super
    if value.is_a? CassandraMapper::EmbeddedDocument
      @attributes[name].embed_will_change = lambda { attribute_will_change!(name) }
    end
  end
end
