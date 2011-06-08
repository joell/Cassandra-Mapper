require 'active_support/concern'

require 'cassandra_mapper/many'

module ManyWrapArrays
  extend ActiveSupport::Concern

  private
  def attribute=(name, value)
    type = self.class.properties[name][:type]
    # if the value is an array and the property is a `many', then convert it
    if type.class == Array && type[0] == CassandraMapper::Many &&
       value.is_a?(Array)
      super(name, CassandraMapper::Many.new(type[1], type[2], value))
    else
      super
    end
  end
end
