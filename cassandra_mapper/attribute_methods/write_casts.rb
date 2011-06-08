require 'active_support/concern'

require 'cassandra_mapper/many'

module WriteCasts
  extend ActiveSupport::Concern

  private
  def attribute=(name, value)
    type = self.class.properties[name][:type]

    # if the value is an array and the property is a `many', then convert it
    if type.class == Array && type[0] == CassandraMapper::Many &&
       value.is_a?(Array)
      super(name, CassandraMapper::Many.new(type[1], type[2], value))

    # support implicit conversion to a string
    elsif type == String
      super(name, value.to_s)

    # everything else can be left as it is (i.e., we don't do further type checking here)
    else
      super
    end
  end
end
