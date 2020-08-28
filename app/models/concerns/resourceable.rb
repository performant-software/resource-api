module Resourceable
  extend ActiveSupport::Concern

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