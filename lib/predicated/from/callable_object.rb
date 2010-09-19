require "predicated/predicate"
require "predicated/from/ruby_code_string"
require "fileutils"

#raise %{
#
#This will never work in ruby 1.9.
#
#see http://blog.zenspider.com/2009/04/parsetree-eol.html
#
#} if RUBY_VERSION =~/^1.9/

FileUtils.mkdir_p("~/.ruby_inline") unless File.exists?("~/.ruby_inline")
#Procs and lambdas are "callable objects"

module Predicated
  
  require_gem_version("ParseTree", "3.0.5", "parse_tree") if RUBY_VERSION < "1.9"
  require "predicated/sexp_patch"

  class Predicate

                                  #hrm
    def self.from_callable_object(context_or_callable_object=nil, context=nil, &block)
      callable_object = nil
      
      if context_or_callable_object.is_a?(Binding) || context_or_callable_object.nil?
        context = context_or_callable_object
        callable_object = block
      else
        callable_object = context_or_callable_object
      end
      
      context ||= callable_object.binding
      
      from_ruby_code_string(TranslateToRubyString.convert(callable_object), context)
    end

    module TranslateToRubyString
      #see http://stackoverflow.com/questions/199603/how-do-you-stringize-serialize-ruby-code
      def self.convert(callable_object)
        temp_class = Class.new
        temp_class.class_eval do
          define_method :serializable, &callable_object
        end
        ruby_code_string = Ruby2Ruby.translate(temp_class, :serializable)    
        ruby_code_string.sub(/^def serializable\n  /, "").sub(/\nend$/, "")
      end
    end

  end
end
