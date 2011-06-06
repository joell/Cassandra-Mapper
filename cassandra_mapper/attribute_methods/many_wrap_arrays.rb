require 'active_support/concern'

require 'cassandra_mapper/many'

module ManyWrapArrays
  extend ActiveSupport::Concern

  private
  def attribute=(name, value)
    # if the value is an array and the property is a `many', then convert it
    if CassandraMapper::Many == self.class.properties[name][:type] &&
       value.is_a?(Array)
      super(name, CassandraMapper::Many.new(value))
    else
      super
    end
  end
end
