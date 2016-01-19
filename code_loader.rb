module Micro
  class CodeLoader
    OPCODES = [:push_literal, :push_local, :pop, :add, :sub, :mul, :div, :call, :ret ]

    def initialize
      @functions = []
    end

    def load_file(filename)
      file = File.open(filename)

      while !file.eof? && line = file.readline
        if line =~/^_/
          load_function line
        elsif line =~/^:/
          load_function_arguments line
        else
          opcode, operand = line.split('.').map(&:to_i) 
          @functions.last.code.push VM::Instruction.new(OPCODES[opcode], operand)
        end
      end
      @functions
    end

    private
    def load_function function
      @functions.push VM::Function.new(function.chomp[1..-2].to_sym)
      @functions.last.code = []
      @functions.last.operands = []
    end

    def load_function_arguments arguments
      @functions.last.operands = arguments[1..-1].split(',').map do |argument|
        if argument =~ /\"/
          argument.chomp[1..-2]
        else
          argument.to_i
        end
      end
    end
  end
end
