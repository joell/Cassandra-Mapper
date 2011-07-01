require 'active_support/concern'
require 'active_support/json'
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

    def initialize(elem_type, root_name=elem_type.model_name.collection, es=[])
      @etype = elem_type
      @root_name = root_name
      @embeds = []

      es.each {|e| self << e}
      changed_attributes.clear
      self
    end

    def initialize_copy(source)
      super
      @embeds = @embeds.dup
    end

    def each(&block)
      embeds.each(&block)
    end

    def <<(embed)
      embeds_will_change!
      embeds << associate(convert(embed))
    end

    def [](index)
      embeds[index]
    end

    def []=(index, embed)
      embeds_will_change!
      embeds[index] = associate(convert(embed))
    end

    def clear
      embeds_will_change!
      @embeds = []
    end

    #
    # JSON serialization
    #

    def as_json(*args)
      @embeds.map {|e| e.as_json(*args)}
    end

    def to_json
      as_json.to_json
    end

    def save_to_bytes
      to_json.tap do
        changed_attributes.clear
      end
    end

    class << self
      def from_json(json, elem_type, root_name=elem_type.model_name.collection)
        elems = ActiveSupport::JSON.decode(json)
        unless elems.class <= Array
          raise TypeError, "Many must have an array JSON representation"
        end
        new(elem_type, root_name, elems)
      end

      alias_method :load, :from_json
    end

    #
    # Recursive dirty-change tracking
    #

    private
    def embeds_will_change!
      embed_will_change.call  if embed_will_change
      super
    end

    def convert(embed)
      # if the embedded document was passed as a JSON-structured hash, then
      #   build the actual EmbeddedDocument-deriving class from it
      if embed.class <= Hash
        @etype.new(embed)
      else
        embed
      end
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
