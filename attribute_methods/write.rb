require 'active_support/concern'

module Write
  extend ActiveSupport::Concern

  included do
    attribute_method_suffix '='
  end

  private
  def attribute=(name, value)
    @attributes[name] = value
  end
end
