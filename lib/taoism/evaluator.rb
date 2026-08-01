module Taoism
  class Evaluator
    def initialize
      @global = Environment.new
      @methods = {}
      @builtins = {
        'io.println' => proc { |arg| puts arg.to_s }
      }
      @in_loop = false
    end

    def evaluate(node, env = @global)
      case node
      when Nodes::Program
        node.stmts.map { |s| evaluate(s, env) }.last
      when Nodes::Block
        inner = Environment.new(env)
        last = nil

        node.stmts.each { |s| last = evaluate(s, inner) }
        last
      when Nodes::ExprStmt  then evaluate(node.expr, env)
      when Nodes::IntLit    then node.value
      when Nodes::FloatLit  then node.value
      when Nodes::StringLit
        node.value.gsub(/\\(\\|"|n|r|t|0|\((\w+)\))/) do
          case $1
          when '\\' then '\\'
          when '"'  then '"'
          when 'n'  then "\n"
          when 'r'  then "\r"
          when 't'  then "\t"
          when '0'  then "\0"
          else env.get($2).to_s
          end
        end
      when Nodes::BoolLit   then node.value
      when Nodes::NoneLit   then nil
      when Nodes::ListLit
        node.elements.map { |e| evaluate(e, env) }
      when Nodes::Identifier then env.get(node.name)
      when Nodes::Let
        val = evaluate(node.value, env)
        env.define(node.name, val, mutable: node.mutable)
        val
      when Nodes::LetPair
        values = evaluate(node.expr, env)
        env.define(node.first, values[0], mutable: false)
        env.define(node.second, values[1], mutable: false)
        values
      when Nodes::Assign
        val = evaluate(node.value, env)

        case node.target
        when Nodes::Identifier
          env.set(node.target.name, val)
        when Nodes::DotExpr
          target = evaluate(node.target.target, env)

          unless target.is_a?(Runtime::Instance)
            raise Runtime::Error, "field access on non-instance"
          end

          unless target.fields.key?(node.target.name)
            raise Runtime::Error, "undefined field: #{node.target.name}"
          end

          target.fields[node.target.name] = val
        when Nodes::Index
          target = evaluate(node.target.target, env)

          unless target.respond_to?(:[]=)
            raise Runtime::Error, "index assignment on non-indexable"
          end

          index = evaluate(node.target.index, env)

          unless index.is_a?(Integer)
            raise Runtime::Error, "index must be an integer: #{index}"
          end

          target[index] = val
        else
          raise Runtime::Error, "invalid assignment target"
        end

        val
      when Nodes::Const
        val = evaluate(node.value, env)
        env.define(node.name, val, mutable: false)
        val
      when Nodes::BinaryOp
        left = evaluate(node.left, env)
        case node.op
        when :and then left && evaluate(node.right, env)
        when :or  then left || evaluate(node.right, env)
        else
          right = evaluate(node.right, env)

          if %i(+ - * / % < <= > >=).include?(node.op)
            unless Types.numeric?(left) && Types.numeric?(right)
              raise Runtime::Error, "cannot apply #{node.op} to #{Types.typeof(left)} and #{Types.typeof(right)}"
            end
          end

          if %i(/ %).include?(node.op) && right == 0
            raise Runtime::Error, "cannot divide by zero"
          end

          left.send(node.op, right)
        end
      when Nodes::UnaryOp
        operand = evaluate(node.operand, env)

        if node.op == :'-'
          unless Types.numeric?(operand)
            raise Runtime::Error, "cannot negate #{Types.typeof(operand)}"
          end

          -operand
        else
          !operand
        end
      when Nodes::If
        if evaluate(node.cond, env)
          evaluate(node.then_body, env)
        elsif node.else_body
          evaluate(node.else_body, env)
        else
        end
      when Nodes::Switch
        val = evaluate(node.value, env)
        result = nil
        matched = false

        node.arms.each do |arm|
          if evaluate(arm.pattern, env) == val
            result = evaluate(arm.value, env)
            matched = true
            break
          end
        end

        if !matched && node.else_body
          result = evaluate(node.else_body, env)
        end

        result
      when Nodes::Loop
        prev = @in_loop
        @in_loop = true

        loop do
          begin
            evaluate(node.body, Environment.new(env))
          rescue Runtime::Leave
            break
          end
        end

        @in_loop = prev
      when Nodes::Leave
        unless @in_loop
          raise Runtime::Error, "leave outside loop"
        end

        raise Runtime::Leave
      when Nodes::Return
        result = evaluate(node.value, env)
        raise Runtime::Return.new(result)
      when Nodes::FunDef
        fn = Runtime::Function.new(
          node.name, node.params, node.body, env, node.receiver
        )

        if node.receiver
          type_name = node.receiver.type_name

          unless env.has?(type_name) && env.get(type_name).is_a?(Runtime::DataType)
            raise Runtime::Error, "undefined type: #{type_name}"
          end

          fn_name = "#{type_name}.#{node.name}"

          if @methods[fn_name]
            raise Runtime::Error, "already defined method: #{fn_name}"
          end

          @methods[fn_name] = fn
        end

        if node.name
          env.define(node.name, fn, mutable: false)
        end

        fn
      when Nodes::Call
        args = node.args.map { |a| evaluate(a, env) }

        if node.callee.is_a?(Nodes::DotExpr)
          if node.callee.target.is_a?(Nodes::Identifier)
            key = "#{node.callee.target.name}.#{node.callee.name}"
            if fn = @builtins[key]
              return fn.call(*args)
            end
          end

          target = evaluate(node.callee.target, env)

          unless target.is_a?(Runtime::Instance)
            raise Runtime::Error, "method call on non-instance"
          end

          key = "#{target.type}.#{node.callee.name}"
          fn = @methods[key]

          unless fn
            raise Runtime::Error, "undefined method: #{key}"
          end

          if args.length != fn.params.length
            raise Runtime::Error, arity_error(fn.params.length, args.length)
          end

          call_env = Environment.new(fn.closure)
          call_env.define(fn.receiver.param_name, target, mutable: true)

          fn.params.each_with_index do |p, i|
            call_env.define(p, args[i], mutable: true)
          end

          begin
            evaluate(fn.body, call_env)
          rescue Runtime::Return => ret
            ret.value
          end
        else
          callee = evaluate(node.callee, env)
          case callee
          when Runtime::Function
            if args.length != callee.params.length
              raise Runtime::Error, arity_error(callee.params.length, args.length)
            end

            call_env = Environment.new(callee.closure)
            callee.params.each_with_index do |p, i|
              call_env.define(p, args[i], mutable: true)
            end

            begin
              evaluate(callee.body, call_env)
            rescue Runtime::Return => ret
              ret.value
            end
          when Runtime::DataType
            fields = {}

            if args.length > callee.fields.length
              raise Runtime::Error, arity_error("at most #{callee.fields.length}", args.length)
            end

            callee.fields.each_with_index do |f, i|
              fields[f.name] = args.length > i ? args[i] : evaluate(f.default, env)
            end

            Runtime::Instance.new(callee.name, fields)
          else
            raise Runtime::Error, "not callable: #{callee.inspect}"
          end
        end
      when Nodes::DotExpr
        target = evaluate(node.target, env)

        if target.is_a?(Runtime::Instance)
          unless target.fields.key?(node.name)
            raise Runtime::Error, "undefined field: #{node.name}"
          end

          target.fields[node.name]
        else
          raise Runtime::Error, "field access on non-instance"
        end
      when Nodes::Index
        index = evaluate(node.index, env)
        target = evaluate(node.target, env)

        unless index.is_a?(Integer)
          raise Runtime::Error, "index must be an integer: #{index}"
        end

        unless target.respond_to?(:[])
          raise Runtime::Error, "index access on non-indexable"
        end

        target[index]
      when Nodes::DataDef
        node.fields.each do |field|
          next if field.default.nil?
          unless literal?(field.default)
            raise Runtime::Error, "field default must be a literal: #{field.name}"
          end
        end

        value = Runtime::DataType.new(node.name, node.fields)
        env.define(node.name, value, mutable: false)
        value
      when Nodes::Try
        begin
          [nil, evaluate(node.call, env)]
        rescue Runtime::Error => err
          [err.message, nil]
        end
      when Nodes::Package then nil
      when Nodes::Import  then nil
      when nil            then nil
      else
        raise Runtime::Error, "unknown node: #{node.class}"
      end
    end

    def arity_error(expected, got)
      "expected #{expected} argument(s) but got #{got}"
    end

    def literal?(node)
      case node
      when Nodes::IntLit,
           Nodes::FloatLit,
           Nodes::StringLit,
           Nodes::BoolLit,
           Nodes::NoneLit
        true
      when Nodes::ListLit
        node.elements.all? { |el| literal?(el) }
      else
        false
      end
    end
  end
end
