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

        if node.target.is_a?(Nodes::Identifier)
          env.set(node.target.name, val)
        else
          target = evaluate(node.target.target, env)
          case node.target
          when Nodes::DotExpr
            unless target.is_a?(Runtime::Instance)
              raise Runtime::Error, "field access on non-instance"
            end

            target.fields[node.target.name] = val
          when Nodes::Index
            unless target.respond_to?(:[]=)
              raise Runtime::Error, "index assignment on non-indexable"
            end

            target[evaluate(node.target.index, env)] = val
          else
          end
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
          left.send(node.op, evaluate(node.right, env))
        end
      when Nodes::UnaryOp
        operand = evaluate(node.operand, env)
        node.op == :'-' ? -operand : !operand
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

        node.arms.each do |arm|
          if evaluate(arm.pattern, env) == val
            result = evaluate(arm.value, env)
            break
          end
        end

        if result.nil? && node.else_body
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
          fn_name = "#{node.receiver.type_name}.#{node.name}"

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
          target.fields[node.name]
        else
          raise Runtime::Error, "field access on non-instance"
        end
      when Nodes::Index
        index = evaluate(node.index, env)
        target = evaluate(node.target, env)

        unless target.respond_to?(:[])
          raise Runtime::Error, "index access on non-indexable"
        end

        target[index]
      when Nodes::DataDef
        value = Runtime::DataType.new(node.name, node.fields)
        env.define(node.name, value, mutable: false)
      when Nodes::Try
        begin
          [nil, evaluate(node.call, env)]
        rescue Runtime::Error => err
          [err.message, nil]
        end
      when Nodes::Package then nil
      when Nodes::Import  then nil
      else
      end
    end

    def arity_error(expected, got)
      "expected #{expected} argument(s) but got #{got}"
    end
  end
end
