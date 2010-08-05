require "predicated/predicate"

module Predicated
  
  require_gem_version("treetop", "1.4.8")
  
  module Predicate
    def self.from_url_part(url_part)
      TreetopUrlPartParser.new.parse(url_part).to_predicate
    end
  end

  module TreetopUrlPart
    Treetop.load_from_string(%{

grammar TreetopUrlPart

include Predicated::TreetopUrlPart

rule or
  ( and "|" or <OrNode>)  / and
end 

rule and
  ( leaf "&" and <AndNode> ) / leaf
end

rule operation
  unquoted_string sign unquoted_string <OperationNode>
end

rule parens
  "(" or ")" <ParensNode>
end


rule leaf
  operation / parens
end

rule unquoted_string
  [0-9a-zA-Z]*
end

rule sign
  ('>=' / '<=' / '<' / '>' / '=' )
end
end

})
  
    class OperationNode < Treetop::Runtime::SyntaxNode
      def left_text; elements[0].text_value end
      def sign_text; elements[1].text_value end
      def right_text; elements[2].text_value end      
      
      SIGN_TO_PREDICATE_CLASS = {
        "=" => Equal, 
        ">" => GreaterThan,
        "<" => LessThan,
        ">=" => GreaterThanOrEqualTo,
        "<=" => LessThanOrEqualTo
      }
      
      def to_predicate
        SIGN_TO_PREDICATE_CLASS[sign_text].new(left_text, right_text)
      end
    end      
    
    class AndNode < Treetop::Runtime::SyntaxNode
      def left; elements[0] end
      def right; elements[2] end      
      
      def to_predicate
        And.new(left.to_predicate, right.to_predicate)
      end
    end
          
    class OrNode < Treetop::Runtime::SyntaxNode
      def left; elements[0] end
      def right; elements[2] end      
      
      def to_predicate
        Or.new(left.to_predicate, right.to_predicate)
      end
    end
    
    class ParensNode < Treetop::Runtime::SyntaxNode
      def inner; elements[1] end
      
      def to_predicate
        inner.to_predicate
      end
    end
    
  end
end