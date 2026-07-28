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

    Function = Struct.new(:name, :params, :body, :closure, :receiver) do
      def to_s
        "<fun #{name || '(lambda)'}>"
      end
    end

    DataType = Struct.new(:name, :fields) do
      def to_s
        "<data #{name}>"
      end
    end

    Instance = Struct.new(:type, :fields) do
      def to_s
        fields_kv = fields.map { |k, v| "#{k}=#{v}" }
        "#{type}(#{fields_kv.join(', ')})"
      end
    end
  end
end
