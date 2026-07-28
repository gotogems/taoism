module Taoism
  class Console
    def initialize
      @evaluator = Evaluator.new
    end

    def run
      require 'readline'

      loop do
        input = prompt('taoism> ')
        break unless input

        break if input.strip == 'exit'
        evaluate(input)
      end
    end

    def prompt(prefix = '> ')
      input = Readline.readline(prefix, true)
      return if input.nil?
      input = input.chomp

      while unclosed?(input)
        line = Readline.readline('..... ', true)
        break unless line
        input << line.chomp
      end

      input
    end

    def evaluate(input)
      lexer = Lexer.new(input)
      parser = Parser.new(lexer)

      ast = parser.parse

      if parser.errors.empty?
        result = @evaluator.evaluate(ast)
        puts display(result)
      else
        parser.errors.each do |err|
          $stderr.puts "Error: #{err}"
        end
      end
    rescue Runtime::Error => err
      $stderr.puts "Error: #{err.message}"
    end

    def display(value)
      case value
      when nil    then 'None'
      when true   then 'True'
      when false  then 'False'
      when String then %Q("#{value}")
      when Array  then "[#{value.map { display(_1) }.join(', ')}]"
      else value.to_s
      end
    end

    def unclosed?(input)
      nesting('{', '}', input) > 0
    end

    def nesting(open, close, str)
      str.count(open) - str.count(close)
    end
  end
end
