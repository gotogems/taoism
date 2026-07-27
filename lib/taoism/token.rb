module Taoism
  Token = Data.define(:type, :lexeme, :value, :start, :end)

  class Token
    Position = Data.define(:offset, :line, :col)
  end
end
