class Taoism::Parser

token
  ILLEGAL IDENTIFIER STRING FLOAT INT BOOL
  PLUS MINUS STAR SLASH MODULO
  GREATER GREATEREQ LESS LESSEQ EQUAL EQUALEQ BANG BANGEQ
  AND OR NOT PIPE
  LBRACE RBRACE LSQUARE RSQUARE LPAREN RPAREN
  COMMA COLON SEMI DOT
  IF ELSE LOOP LEAVE SWITCH
  PACKAGE IMPORT CONST DATA FUN LET MUT TRY RETURN
  EQARROW ARROW EOF

prechigh
  left DOT LSQUARE LPAREN
  right UMINUS
  left STAR SLASH MODULO
  left PLUS MINUS
  nonassoc GREATER GREATEREQ LESS LESSEQ
  nonassoc EQUALEQ BANGEQ
  left AND
  left OR
preclow

rule
  program : top_stmts
    {
      first = val[0].first
      last  = val[0].last
      result = Nodes::Program.new(val[0],
        first ? first.start : nil,
        last  ? last.end   : nil)
    }

  top_stmts : /* none */
    { result = [] }
            | top_stmts top_stmt
    { val[0] << val[1]; result = val[0] }
            | top_stmts top_stmt SEMI
    { val[0] << val[1]; result = val[0] }

  top_stmt : const_stmt
           | fun_def
           | data_def
           | import_stmt
           | package_stmt
           | expr_stmt

  block_stmts : /* none */
    { result = [] }
              | block_stmts block_stmt
    { val[0] << val[1]; result = val[0] }
              | block_stmts block_stmt SEMI
    { val[0] << val[1]; result = val[0] }

  block_stmt : let_stmt
             | assign_stmt
             | return_stmt
             | leave_stmt
             | loop_stmt
             | expr_stmt

  let_stmt : LET IDENTIFIER EQUAL expr
    { result = Nodes::Let.new(val[1].lexeme, val[3], false,
        val[0].start, val[3].end) }
           | LET MUT IDENTIFIER EQUAL expr
    { result = Nodes::Let.new(val[2].lexeme, val[4], true,
        val[0].start, val[4].end) }
           | LET IDENTIFIER COMMA IDENTIFIER EQUAL expr
    { result = Nodes::LetDestructure.new(val[1].lexeme, val[3].lexeme, val[5],
        val[0].start, val[5].end) }

  assign_stmt : postfix_expr EQUAL expr
    { result = Nodes::Assign.new(val[0], val[2],
        val[0].start, val[2].end) }

  const_stmt : CONST IDENTIFIER EQUAL expr
    { result = Nodes::Const.new(val[1].lexeme, val[3],
        val[0].start, val[3].end) }

  import_stmt : IMPORT path
    { result = Nodes::Import.new(val[1],
        val[0].start, val[0].end) }

  package_stmt : PACKAGE IDENTIFIER
    { result = Nodes::Package.new(val[1].lexeme,
        val[0].start, val[1].end) }

  path : IDENTIFIER              { result = val[0].lexeme }
       | path DOT IDENTIFIER     { result = val[0] + '.' + val[2].lexeme }

  return_stmt : RETURN expr
    { result = Nodes::Return.new(val[1],
        val[0].start, val[1].end) }

  leave_stmt : LEAVE
    { result = Nodes::Leave.new(val[0].start, val[0].end) }

  expr_stmt : expr
    { result = Nodes::ExprStmt.new(val[0],
        val[0].start, val[0].end) }

  fun_def : FUN IDENTIFIER LPAREN params RPAREN block
    { result = Nodes::FunDef.new(val[1].lexeme, val[3], val[5], nil,
        val[0].start, val[5].end) }
          | FUN LPAREN IDENTIFIER IDENTIFIER RPAREN
                 IDENTIFIER LPAREN params RPAREN block
    { result = Nodes::FunDef.new(val[5].lexeme, val[8], val[9],
        Nodes::Receiver.new(val[2].lexeme, val[3].lexeme,
          val[1].start, val[4].end),
        val[0].start, val[9].end) }

  params : /* none */            { result = [] }
         | param_list            { result = val[0] }

  param_list : IDENTIFIER                 { result = [val[0].lexeme] }
             | param_list COMMA IDENTIFIER { val[0] << val[2].lexeme; result = val[0] }

  data_def : DATA IDENTIFIER LBRACE field_list RBRACE
    { result = Nodes::DataDef.new(val[1].lexeme, val[3],
        val[0].start, val[4].end) }

  field_list : field                   { result = [val[0]] }
             | field_list field        { val[0] << val[1]; result = val[0] }

  field : IDENTIFIER
    { result = Nodes::Field.new(val[0].lexeme, nil,
        val[0].start, val[0].end) }
        | IDENTIFIER EQUAL expr
    { result = Nodes::Field.new(val[0].lexeme, val[2],
        val[0].start, val[2].end) }

  block : LBRACE block_stmts RBRACE
    { result = Nodes::Block.new(val[1],
        val[0].start, val[2].end) }

  expr : or_expr { result = val[0] }

  or_expr : and_expr
          | or_expr OR and_expr
    { result = Nodes::BinaryOp.new(val[0], :or, val[2],
        val[0].start, val[2].end) }

  and_expr : cmp_expr
           | and_expr AND cmp_expr
    { result = Nodes::BinaryOp.new(val[0], :and, val[2],
        val[0].start, val[2].end) }

  cmp_expr : add_expr
           | cmp_expr EQUALEQ add_expr
    { result = Nodes::BinaryOp.new(val[0], :'==', val[2],
        val[0].start, val[2].end) }
           | cmp_expr BANGEQ add_expr
    { result = Nodes::BinaryOp.new(val[0], :'!=', val[2],
        val[0].start, val[2].end) }
           | cmp_expr GREATER add_expr
    { result = Nodes::BinaryOp.new(val[0], :'>', val[2],
        val[0].start, val[2].end) }
           | cmp_expr GREATEREQ add_expr
    { result = Nodes::BinaryOp.new(val[0], :'>=', val[2],
        val[0].start, val[2].end) }
           | cmp_expr LESS add_expr
    { result = Nodes::BinaryOp.new(val[0], :'<', val[2],
        val[0].start, val[2].end) }
           | cmp_expr LESSEQ add_expr
    { result = Nodes::BinaryOp.new(val[0], :'<=', val[2],
        val[0].start, val[2].end) }

  add_expr : mul_expr
           | add_expr PLUS mul_expr
    { result = Nodes::BinaryOp.new(val[0], :'+', val[2],
        val[0].start, val[2].end) }
           | add_expr MINUS mul_expr
    { result = Nodes::BinaryOp.new(val[0], :'-', val[2],
        val[0].start, val[2].end) }

  mul_expr : unary_expr
           | mul_expr STAR unary_expr
    { result = Nodes::BinaryOp.new(val[0], :'*', val[2],
        val[0].start, val[2].end) }
           | mul_expr SLASH unary_expr
    { result = Nodes::BinaryOp.new(val[0], :'/', val[2],
        val[0].start, val[2].end) }
           | mul_expr MODULO unary_expr
    { result = Nodes::BinaryOp.new(val[0], :'%', val[2],
        val[0].start, val[2].end) }

  unary_expr : MINUS unary_expr = UMINUS
    { result = Nodes::UnaryOp.new(:'-', val[1],
        val[0].start, val[1].end) }
             | BANG unary_expr
    { result = Nodes::UnaryOp.new(:'!', val[1],
        val[0].start, val[1].end) }
             | NOT unary_expr
    { result = Nodes::UnaryOp.new(:'!', val[1],
        val[0].start, val[1].end) }
             | postfix_expr

  postfix_expr : primary
               | IDENTIFIER
    { result = Nodes::Identifier.new(val[0].lexeme,
        val[0].start, val[0].end) }
               | postfix_expr LPAREN args RPAREN
    { result = Nodes::Call.new(val[0], val[2],
        val[0].start, val[3].end) }
               | postfix_expr LSQUARE expr RSQUARE
    { result = Nodes::Index.new(val[0], val[2],
        val[0].start, val[3].end) }
               | postfix_expr DOT IDENTIFIER
    { result = Nodes::MemberAccess.new(val[0], val[2].lexeme,
        val[0].start, val[2].end) }

  primary : INT
    { result = Nodes::IntLit.new(parse_int(val[0]),
        val[0].start, val[0].end) }
          | FLOAT
    { result = Nodes::FloatLit.new(parse_float(val[0]),
        val[0].start, val[0].end) }
          | STRING
    { result = Nodes::StringLit.new(parse_string(val[0]),
        val[0].start, val[0].end) }
          | BOOL
    { result = Nodes::BoolLit.new(val[0].lexeme == 'True',
        val[0].start, val[0].end) }
          | LPAREN expr RPAREN
    { result = val[1] }
          | list_lit
          | if_expr
          | switch_expr
          | try_expr
          | fun_lit

  list_lit : LSQUARE args RSQUARE
    { result = Nodes::ListLit.new(val[1],
        val[0].start, val[2].end) }
           | LSQUARE RSQUARE
    { result = Nodes::ListLit.new([],
        val[0].start, val[1].end) }

  args : expr             { result = [val[0]] }
       | args COMMA expr  { val[0] << val[2]; result = val[0] }

  if_expr : IF expr block else_clause
    { result = Nodes::If.new(val[1], val[2], val[3],
        val[0].start, val[3] ? val[3].end : val[2].end) }

  else_clause : ELSE block    { result = val[1] }
              | ELSE if_expr  { result = val[1] }
              | /* none */    { result = nil }

  loop_stmt : LOOP block
    { result = Nodes::Loop.new(val[1], val[0].start, val[1].end) }

  switch_expr : SWITCH expr LBRACE switch_body RBRACE
    { result = Nodes::Switch.new(val[1], val[3], nil,
        val[0].start, val[4].end) }
              | SWITCH expr LBRACE switch_body else_arm RBRACE
    { result = Nodes::Switch.new(val[1], val[3], val[4],
        val[0].start, val[5].end) }
              | SWITCH expr LBRACE else_arm RBRACE
    { result = Nodes::Switch.new(val[1], [], val[3],
        val[0].start, val[4].end) }

  switch_body : switch_arm             { result = [val[0]] }
              | switch_body switch_arm { val[0] << val[1]; result = val[0] }

  switch_arm : expr EQARROW expr
    { result = Nodes::SwitchArm.new(val[0], val[2],
        val[0].start, val[2].end) }

  else_arm : ELSE EQARROW expr { result = val[2] }

  try_expr : TRY postfix_expr
    { result = Nodes::Try.new(val[1],
        val[0].start, val[1].end) }

  fun_lit : FUN ARROW LPAREN params RPAREN block
    { result = Nodes::FunDef.new(nil, val[3], val[5], nil,
        val[0].start, val[5].end) }

end

---- inner

attr_reader :errors

def initialize(lexer)
  @lexer = lexer
  @errors = []
end

def parse
  do_parse
end

def next_token
  tok = @lexer.next_token
  return nil if tok.type == TokenType::EOF
  [tok.type, tok]
end

def on_error(error_id, val, stack)
  tok = Array(val).first
  msg = if tok.respond_to?(:lexeme)
    "unexpected token #{tok.lexeme.inspect} at #{tok.start.line}:#{tok.start.col}"
  else
    "parse error"
  end
  @errors << msg
end

private

def identifier_or_none(tok)
  if tok.lexeme == 'None'
    Nodes::NoneLit.new(tok.start, tok.end)
  else
    Nodes::Identifier.new(tok.lexeme, tok.start, tok.end)
  end
end

def parse_int(tok)
  tok.lexeme.delete('_').to_i
end

def parse_float(tok)
  tok.lexeme.delete('_').to_f
end

def parse_string(tok)
  tok.lexeme[1...-1]
end
