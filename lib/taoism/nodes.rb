module Taoism
  module Nodes
    # ── Top Level ──
    Program = Struct.new(:stmts, :start, :end)

    # ── Statements ──
    Let            = Struct.new(:name, :value, :mutable, :start, :end)
    LetPair = Struct.new(:first, :second, :expr, :start, :end)
    Assign         = Struct.new(:target, :value, :start, :end)
    Const          = Struct.new(:name, :value, :start, :end)
    Import         = Struct.new(:path, :start, :end)
    Package        = Struct.new(:name, :start, :end)
    Return         = Struct.new(:value, :start, :end)
    Leave          = Struct.new(:start, :end)
    ExprStmt       = Struct.new(:expr, :start, :end)

    # ── Function ──
    FunDef   = Struct.new(:name, :params, :body, :receiver, :start, :end)
    Receiver = Struct.new(:param_name, :type_name, :start, :end)

    # ── Data ──
    DataDef = Struct.new(:name, :fields, :start, :end)
    Field   = Struct.new(:name, :default, :start, :end)

    # ── Block ──
    Block = Struct.new(:stmts, :start, :end)

    # ── Expressions ──
    BinaryOp     = Struct.new(:left, :op, :right, :start, :end)
    UnaryOp      = Struct.new(:op, :operand, :start, :end)
    Call         = Struct.new(:callee, :args, :start, :end)
    Index        = Struct.new(:target, :index, :start, :end)
    Field = Struct.new(:target, :name, :start, :end)
    Identifier   = Struct.new(:name, :start, :end)

    # ── Literals ──
    IntLit    = Struct.new(:value, :start, :end)
    FloatLit  = Struct.new(:value, :start, :end)
    StringLit = Struct.new(:value, :start, :end)
    BoolLit   = Struct.new(:value, :start, :end)
    NoneLit   = Struct.new(:start, :end)
    ListLit   = Struct.new(:elements, :start, :end)

    # ── Special Forms ──
    Try = Struct.new(:call, :start, :end)

    # ── Control Flow ──
    If        = Struct.new(:cond, :then_body, :else_body, :start, :end)
    Loop      = Struct.new(:body, :start, :end)
    Switch    = Struct.new(:value, :arms, :else_body, :start, :end)
    SwitchArm = Struct.new(:pattern, :value, :start, :end)
  end
end
