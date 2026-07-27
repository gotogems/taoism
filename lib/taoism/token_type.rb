module Taoism
  module TokenType
    ILLEGAL    = :ILLEGAL
    IDENTIFIER = :IDENTIFIER
    STRING     = :STRING
    FLOAT      = :FLOAT
    INT        = :INT
    BOOL       = :BOOL

    PLUS   = :PLUS
    MINUS  = :MINUS
    STAR   = :STAR
    SLASH  = :SLASH
    MODULO = :MODULO

    GREATER   = :GREATER
    GREATEREQ = :GREATEREQ
    LESS      = :LESS
    LESSEQ    = :LESSEQ
    EQUAL     = :EQUAL
    EQUALEQ   = :EQUALEQ
    BANG      = :BANG
    BANGEQ    = :BANGEQ

    AND  = :AND
    OR   = :OR
    NOT  = :NOT
    PIPE = :PIPE

    LBRACE  = :LBRACE
    RBRACE  = :RBRACE
    LSQUARE = :LSQUARE
    RSQUARE = :RSQUARE
    LPAREN  = :LPAREN
    RPAREN  = :RPAREN

    COMMA = :COMMA
    COLON = :COLON
    SEMI  = :SEMI
    DOT   = :DOT

    IF      = :IF
    ELSE    = :ELSE
    LOOP    = :LOOP
    LEAVE   = :LEAVE
    SWITCH  = :SWITCH
    PACKAGE = :PACKAGE
    IMPORT  = :IMPORT
    CONST   = :CONST
    DATA    = :DATA
    FUN     = :FUN
    LET     = :LET
    MUT     = :MUT
    TRY     = :TRY
    RETURN  = :RETURN

    EQARROW = :EQARROW
    ARROW   = :ARROW
    EOF     = :EOF
  end
end
