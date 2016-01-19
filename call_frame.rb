require './micro_vm'

module Micro
  class CallFrame
    def initialize(state, function, locals = [], depth=0)
      @state = state
      @code = function.code
      @literals = function.operands
      @locals = locals
      @depth = depth
      @stack = []
    end

    def execute
      @code.each do |instruction|
        case instruction.opcode
        when :push_literal
          @stack.push @literals[instruction.opcode]
        when :push_local
          @stack.push @literals[instruction.opcode]
        when :pop
          @stack.pop
        when :add
          operand_one = @stack.pop
          operand_two = @stack.pop
          check_type(Fixnum, operand_one, operand_two)
          @stack.push operand_one + operand_two
        when :sub
          operand_one = @stack.pop
          operand_two = @stack.pop
          check_type(Fixnum, operand_one, operand_two)
          @stack.push operand_one - operand_two
        when :mul
          operand_one = @stack.pop
          operand_two = @stack.pop
          check_type(Fixnum, operand_one, operand_two)
          @stack.push operand_one * operand_two
        when :div
          operand_one = @stack.pop
          operand_two = @stack.pop
          check_type(Fixnum, operand_one, operand_two)
          raise ZeroDivisionError, "cant divide by zero" if operand_two == 0
          @stack.push operand_one / operand_two
        when :call
          argsnum = instruction.operand
          function_name = @stack.pop
          function = @state.find_function(function_name)
          locals = []
          argsnum.times { locals.push @stack.pop }

          if !function
            raise Namerror, "function #{function_name} doesnot exist"
          end

          if @depth > VM::MAX_STACK_DEPTH
            raise "Call stack level too deep"
          end

          CallFrame.new(@state, function, locals, @depth + 1)
        when :ret
          @stack.pop
        end
      end
      raise "Broken bytecode: lack of RET code"
    end

    def check_type(type, *operands)
      operands.each do |operand|
        raise TypeError, "#{operand.inspect} is not a #{type}" unless operand.is_a?(type)
      end
    end

  end
end
