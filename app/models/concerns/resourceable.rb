module Resourceable
  extend ActiveSupport::Concern

  included do
    before_create :set_booleans

    private

    # Default any boolean columns to "false" if a value is not provided
    def set_booleans
      boolean_attributes = self
                             .class.columns_hash
                             .select{ |k,v| v.type == :boolean }
                             .map{ |k, v| k }

      boolean_attributes.each do |attribute|
        self[attribute.to_sym] = false unless self[attribute.to_sym].present?
      end
    end
  end

  class << self
    def included(base)
      base.extend ClassMethods
    end
  end

  module ClassMethods

    def allow_params(*params)
      @params ||= []
      @params += params
    end

    def permitted_params
      @params
    end
  end

end
