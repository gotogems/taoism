module Taoism
  class Lexer
    KEYWORDS = {
      'if'      => TokenType::IF,
      'else'    => TokenType::ELSE,
      'loop'    => TokenType::LOOP,
      'leave'   => TokenType::LEAVE,
      'switch'  => TokenType::SWITCH,
      'package' => TokenType::PACKAGE,
      'import'  => TokenType::IMPORT,
      'const'   => TokenType::CONST,
      'data'    => TokenType::DATA,
      'fun'     => TokenType::FUN,
      'let'     => TokenType::LET,
      'mut'     => TokenType::MUT,
      'try'     => TokenType::TRY,
      'return'  => TokenType::RETURN,
      'and'     => TokenType::AND,
      'or'      => TokenType::OR,
      'not'     => TokenType::NOT,
    }.freeze

    PUNCTUATION = {
      '{' => TokenType::LBRACE,
      '}' => TokenType::RBRACE,
      '[' => TokenType::LSQUARE,
      ']' => TokenType::RSQUARE,
      '(' => TokenType::LPAREN,
      ')' => TokenType::RPAREN,
      ',' => TokenType::COMMA,
      ':' => TokenType::COLON,
      ';' => TokenType::SEMI,
      '.' => TokenType::DOT,
    }.freeze

    attr_reader :errors

    def initialize(source)
      @source = source
      @offset = 0
      @line   = 1
      @col    = 0
      @errors = ErrorHandler.new
    end

    def next_token
      loop do
        return eof_token if at_end?
        @start = pos

        char = advance
        next if whitespace?(char)

        if char == '/' && peek == '/'
          skip_line_comment
          next
        end

        return scan_token(char)
      end
    end

    def skip_line_comment
      advance
      until at_end? || peek == "\n"
        advance
      end
    end

    def scan_token(char)
      type = PUNCTUATION[char]
      return make_token(type) if type

      case char
      when '+' then make_token(TokenType::PLUS)
      when '-'
      match('>') ? make_token(TokenType::ARROW) : make_token(TokenType::MINUS)
      when '*' then make_token(TokenType::STAR)
      when '/' then make_token(TokenType::SLASH)
      when '%' then make_token(TokenType::MODULO)
      when '>'
        match('=') ? make_token(TokenType::GREATEREQ) : make_token(TokenType::GREATER)
      when '<'
        match('=') ? make_token(TokenType::LESSEQ) : make_token(TokenType::LESS)
      when '='
        if match('=')
          make_token(TokenType::EQUALEQ)
        elsif match('>')
          make_token(TokenType::EQARROW)
        else
          make_token(TokenType::EQUAL)
        end
      when '!'
        match('=') ? make_token(TokenType::BANGEQ) : make_token(TokenType::BANG)
      when '&'
        match('&') ? make_token(TokenType::AND) : make_token(TokenType::ILLEGAL)
      when '|'
        if match('>')
          make_token(TokenType::PIPE)
        elsif match('|')
          make_token(TokenType::OR)
        else
          make_token(TokenType::ILLEGAL)
        end
      when '?' then make_token(TokenType::ILLEGAL)
      when '0'..'9' then number_token
      when '"' then string_token
      else
        alpha?(char) ? identifier_token : make_token(TokenType::ILLEGAL)
      end
    end

    def identifier_token
      while alpha_numeric?(peek)
        advance
      end

      str = lexeme

      if bool_token?(str)
        make_token(TokenType::BOOL)
      elsif none_token?(str)
        make_token(TokenType::NONE)
      else
        if type = KEYWORDS[str]
          make_token(type)
        else
          make_token(TokenType::IDENTIFIER)
        end
      end
    end

    def string_token
      loop do
        if at_end?
          @errors.add(:unterminated_string, "unterminated string", pos)
          return make_token(TokenType::ILLEGAL, "")
        end

        case peek
        when '"'
          advance
          return make_token(TokenType::STRING)
        when "\n"
          @errors.add(:unterminated_string, "unterminated string", pos)
          return make_token(TokenType::ILLEGAL, "")
        when '\\'
          advance
          if peek == '('
            advance
            while alpha_numeric?(peek)
              advance
            end

            @errors.add(:bad_interpolation, "expected ')'", pos) unless peek == ')'
            advance if peek == ')'

          else
            advance unless at_end?
          end
        else
          advance
        end
      end
    end

    def number_token
      type = TokenType::INT

      while digit?(peek) || peek == '_'
        advance
      end

      if peek == '.' && digit?(peek_next)
        type = TokenType::FLOAT
        advance

        while digit?(peek) || peek == '_'
          advance
        end
      end

      make_token(type)
    end

    def make_token(type, text = lexeme)
      Token.new(type, text, nil, @start, pos)
    end

    def eof_token
      Token.new(TokenType::EOF, "", nil, @start, pos)
    end

    def lexeme
      @source[@start.offset...@offset]
    end

    def pos
      Token::Position.new(@offset, @line, @col)
    end

    def match(expected)
      return false if peek != expected
      advance
      true
    end

    def peek
      return "\0" if at_end?
      @source[@offset]
    end

    def peek_next
      if @offset.next < @source.length
        @source[@offset + 1]
      else
        "\0"
      end
    end

    def advance
      char = @source[@offset]
      @offset += 1
      @col += 1
      char
    end

    def at_end?
      @offset >= @source.length
    end

    def bool_token?(str)
      str == 'True' || str == 'False'
    end

    def none_token?(str)
      str == 'None'
    end

    def whitespace?(char)
      case char
      when ' ', "\t", "\r" then true
      when "\n"
        @line += 1
        @col = 0
        true
      else false
      end
    end

    def alpha_numeric?(char)
      alpha?(char) || digit?(char)
    end

    def alpha?(char)
      ('A' <= char && char <= 'Z') ||
      ('a' <= char && char <= 'z') ||
      char == '_'
    end

    def digit?(char)
      '0' <= char && char <= '9'
    end

    class ErrorHandler
      attr_reader :errors

      def initialize
        @errors = []
      end

      def add(code, message = "", pos = nil)
        @errors << LexicalError.new(code, message, pos)
      end
    end
  end
end
