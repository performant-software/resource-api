class BasePolicy
  class BaseScope
    attr_accessor :current_user
    attr_accessor :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end
  end
end
