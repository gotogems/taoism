module Taoism
  class Environment
    def initialize(outer = nil)
      @outer = outer
      @scope = {}
    end

    def define(name, value, mutable: true)
      if @scope.key?(name)
        raise Runtime::Error, "already defined variable: #{name}"
      end

      @scope[name] = { value: value, mutable: mutable }
    end

    def get(name)
      if @scope.key?(name)
        @scope[name][:value]
      elsif @outer
        @outer.get(name)
      else
        raise Runtime::Error, "undefined variable: #{name}"
      end
    end

    def set(name, value)
      if @scope.key?(name)
        if @scope[name][:mutable]
          @scope[name][:value] = value
        else
          raise Runtime::Error, "cannot assign to immutable variable"
        end
      elsif @outer
        @outer.set(name, value)
      else
        raise Runtime::Error, "undefined variable: #{name}"
      end
    end
  end
end
