require 'active_support/concern'
require 'active_model/attribute_methods'
require 'active_model/dirty'
require 'json'

require 'cassandra_mapper/embedded_document/dirty'

module CassandraMapper
  class Many
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty
    include CassandraMapper::EmbeddedDocument::Dirty

    #
    # (Limited) array emulation
    #

    include Enumerable

    def initialize(es=[])
      @embeds = es.map {|e| associate(e)}
    end

    def each(&block)
      embeds.each(&block)
    end

    def <<(embed)
      embeds_will_change!
      embeds << associate(embed)
    end

    def [](index)
      embeds[index]
    end

    def []=(index, embed)
      embeds_will_change!
      embeds[index] = associate(embed)
    end

    #
    # JSON serialization
    #

    def save_to_bytes
      {
        JSON.create_id => self.class.name,
        :many          => embeds
      }.to_json.tap  { changed_attributes.clear }
    end
    alias_method :to_json, :save_to_bytes

    def self.json_create(json_hash)
      new(json_hash['many'])
    end

    def self.load(str)
      JSON.parse(str).tap do |doc|
        raise TypeError, "JSON does not parse to a #{self.name}"  unless doc.is_a? self
      end
    end

    #
    # Recursive dirty-change tracking
    #

    private
    def embeds_will_change!
      embed_will_change.call  if embed_will_change
      super
    end

    # associate all changes to embeded documents in our array as changes to 
    #   the array itself
    def associate(embed)
      embed.embed_will_change = lambda { embeds_will_change! }
      embed
    end

    attr_accessor :embeds
    define_attribute_methods [:embeds]
  end
end
