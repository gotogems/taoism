module Taoism
  class Console
    PS1 = 'taoism:%03d> '
    PS2 = 'taoism:%03d* '

    def initialize
      @evaluator = Evaluator.new
      @line_no = 1
    end

    def run
      require 'readline'

      loop do
        input = read_input
        break unless input

        break if input.strip == 'exit'
        evaluate(input)
      end
    end

    def read_input
      ps1 = PS1 % @line_no
      ps2 = PS2 % @line_no

      input = Readline.readline(ps1, true)
      return if input.nil?
      input = input.chomp

      had_continuation = false

      while unclosed?(input)
        had_continuation = true
        line = Readline.readline(ps2, false)

        break unless line
        input << line.chomp
      end

      if had_continuation
        Readline::HISTORY.pop
        Readline::HISTORY << input
      end

      @line_no += 1
      input
    end

    def evaluate(input)
      lexer = Lexer.new(input)
      parser = Parser.new(lexer)

      ast = parser.parse

      if parser.errors.empty?
        result = @evaluator.evaluate(ast)
        puts render(result)
      else
        parser.errors.each do |err|
          $stderr.puts "Error: #{err}"
        end
      end
    rescue Runtime::Error, Runtime::Return, Runtime::Leave => err
      $stderr.puts "Error: #{err.message}"
    end

    def render(value)
      case value
      when nil    then 'None'
      when true   then 'True'
      when false  then 'False'
      when String then %Q("#{value}")
      when Array  then "[#{value.map { render(_1) }.join(', ')}]"
      else value.to_s
      end
    end

    def unclosed?(input)
      input.count('{') > input.count('}')
    end
  end
end
