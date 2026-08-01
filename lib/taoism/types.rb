module Taoism
  class Types
    def self.typeof(value)
      case value
      when nil         then 'None'
      when true, false then 'Bool'
      when Integer     then 'Int'
      when Array       then 'List'
      when Runtime::Function then 'Fun'
      when Runtime::DataType then value.name
      when Runtime::Instance then value.type.name
      else value.class.name
      end
    end

    def self.numeric?(value)
      value.is_a?(Integer) or value.is_a?(Float)
    end
  end
end
