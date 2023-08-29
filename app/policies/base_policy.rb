class BasePolicy
  class BaseScope
    attr_accessor :current_user
    attr_accessor :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    def permitted_params
      []
    end
  end
end
