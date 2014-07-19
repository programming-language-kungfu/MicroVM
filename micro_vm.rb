require "code_loader"
require "call_frame"

module Micro
  VERSION = '0.0.1'

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
      @frame = VM::CallFrame.new(self, main) 
      @frame.execute
    end

    def find_function(name)
      @functions.detect {|function| function.name == name.to_sym }
    end 

  end
end

unless ARGV.first
  puts "MicroVM #{Micro::VERSION}\n============="
  puts "\tUsage: microvm my_file.mc"
  exit(1)
end


Micro::VM.new.load(ARGV.first).run
