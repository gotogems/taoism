require 'taoism/token_type'
require 'taoism/token'
require 'taoism/nodes'
require 'taoism/lexer'
require 'taoism/parser'

module Taoism
  LexicalError = Struct.new(:code, :message, :pos)
end
