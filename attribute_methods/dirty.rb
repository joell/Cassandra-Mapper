require 'active_model/dirty'
require 'active_support/concern'

module Dirty
  extend ActiveSupport::Concern
  include ActiveModel::Dirty

  def save(*args)
    super(*args).tap do
      changed_attributes.clear
    end
  end

  private
  def attribute=(name, value)
    if self.class.properties.has_key?(name) && @attributes[name] != value
      attribute_will_change!(name)
    end
    super
  end
end
