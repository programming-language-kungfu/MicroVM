module Micro; version = '0.0.1'
  
  class CodeLoader
    OPCODES = [:push_literal, :push_local, :pop, :add, :sub, :mul, :div, :call, :ret ]

    def self.load_file(filename)
      functions = []
      file = File.open(filename)

      while !file.eof? && line = file.readline
        if line =~/^_/
          functions.push VM::function.new(line.chomp[1..-2].to_sym)
          functions.last.code = []
          functions.last.literals = []
        elsif line =~/^:/
          functions.last.literals = line[1..-1].split(',').map do |literal|
            if literal = /\"/
              literal.chomp[1..-2]
            else
              literal.to_i
            end
          end

        else
          opcode, operand = line.split('.').map(&:to_i) 
          functions.last.code.push VM::Instruction.new(OPCODES[opcode], operand)
        end
      end

      return functions
    end
  end

  class VM
    Instruction = Struct.new(:opcode, :operand)
    Function = Struct.new(:name, :code, :operand)

    MAX_STACK_DEPTH = 128

    def load(filename)
      @functions = CodeLoader.load_file(filename)
      self
    end

    def run()
      main = find_function(:main)
      @frame = CallFrame.new(self, main)
      p @frame.execute
    end

    def find_function(name)
      @functions.detect {|m| m.name == name.to_sym }
    end

    class CallFrame

      def initialize(state, function, local = [], depth=0)
        @state = state
        @code = function.code
        @literals = function.literals
        @locals = locals
        @depth = depth
        @stack = []
      end

      def execute
        @code.each |instruction| do
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
            raise ZeroDivisionError if operand_two == 0
            @stack.push operand_one / operand_two
          when :call
            argnums = instruction.operand
            function_name = @stack.pop
            function = @state.find_function(function_name)

            locals = []
            argsnum.times { locals.push @stack.pop }

            if !function
              raise Namerror, "function #{function_name} doesnot exist"
            end

            if @depth > MAX_STACK_DEPTH
              raise "Call stack level too deep"
            end

            call_frame = CallFrame.new(@state, function, locals, @depth + 1)
            @stack.push call_frame.execute
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
end

unless ARGV.first
  puts "MicroVM #{Micro::VERSION}\n============="
  puts "\tUsage: microvm my_file.mc"
  exit(1)
end


Micro::VM.new.load(ARGV.first).run