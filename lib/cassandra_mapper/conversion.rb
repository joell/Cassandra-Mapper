require 'active_model/conversion'

module CassandraMapper
  module Conversion
    include ActiveModel::Conversion

    def new_record?
      new?
    end

    def persisted?
      !new?
    end

    def to_key
      [key]
    end

    def to_param
      key
    end
  end
end
