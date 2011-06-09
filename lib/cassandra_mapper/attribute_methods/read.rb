require 'active_support/concern'

module Read
  extend ActiveSupport::Concern

  included do
    attribute_method_suffix ''
  end

  private
  def attribute(name)
    @attributes[name] if @attributes.include?(name)
  end
end
