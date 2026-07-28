module Taoism
  module Runtime
    class Return < StandardError
      attr_reader :value

      def initialize(value)
        @value = value
        super
      end
    end

    class Leave < StandardError; end
    class Error < StandardError; end

    Function = Struct.new(:name, :params, :body, :closure, :receiver)
    DataType = Struct.new(:name, :fields)
    Instance = Struct.new(:type, :fields)
  end
end
