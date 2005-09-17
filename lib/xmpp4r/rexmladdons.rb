# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'rexml/document'

# REXML module. This file only adds a few methods to the REXML module, to
# ease the coding.
module REXML
  # this class adds a few helper methods to REXML::Element
  class Element
    ##
    # Replaces or add a child element of name <tt>e</tt> with text <tt>t</tt>.
    def replace_element_text(e, t)
      el = first_element(e)
      if el.nil?
        el = REXML::Element::new(e)
        add_element(el)
      end
      if t
        el.text = t
      end
      self
    end

    ##
    # Returns first element of name <tt>e</tt>
    def first_element(e)
      each_element { |el| return el if el.name == e }
      return nil
    end

    ##
    # Returns text of first element of name <tt>e</tt>
    def first_element_text(e)
      el = first_element(e)
      if el
        return el.text
      else
        return nil
      end
    end

    # This method does exactly the same thing as add(), but it can be
    # overriden by subclasses to provide on-the-fly object creations.
    # For example, if you import a REXML::Element of name 'plop', and you
    # have a Plop class that subclasses REXML::Element, with typed_add you
    # can get your REXML::Element to be "magically" converted to Plop.
    def typed_add(e)
      add(e)
    end

    ##
    # import this element's children and attributes
    def import(xmlelement)
      if @name and @name != xmlelement.name
        raise "Trying to import an #{xmlelement.name} to a #{@name} !"
      end
      add_attributes(xmlelement.attributes.clone)
      @context = xmlelement.context
      xmlelement.each do |e|
        if e.kind_of? REXML::Element
          typed_add(e.deep_clone)
        else # text element, probably.
          add(e.clone)
        end
      end
      self
    end

    ##
    # Deletes one or more children elements,
    # not just one like REXML::Element#delete_element
    def delete_elements(element)
      while(delete_element(element)) do end
    end

#    ##
#    # Workaround for buggy XPath handling in REXML
#    #
#    # See tc_presence [PresenceTest#test_sample] for a test
#    def each_element(xmlelement=nil, &block)
#      if xmlelement.kind_of?(String)
#        if xmlelement =~ /\//
#          super(xmlelement) { |e| yield e }
#        else
#          super() { |e|
#            if e.name == xmlelement
#              yield e
#            end
#          }
#        end
#      else
#        super(xmlelement) { |e| yield e }
#      end
#    end
  end

  # The XPath parser has bugs. Here is a patch.
  class XPathParser
    def expr( path_stack, nodeset, context=nil )
      #puts "#"*15
      #puts "In expr with #{path_stack.inspect}"
      #puts "Returning" if path_stack.length == 0 || nodeset.length == 0
      node_types = ELEMENTS
      return nodeset if path_stack.length == 0 || nodeset.length == 0
      while path_stack.length > 0
        #puts "Path stack = #{path_stack.inspect}"
        #puts "Nodeset is #{nodeset.inspect}"
        case (op = path_stack.shift)
        when :document
          nodeset = [ nodeset[0].root_node ]
          #puts ":document, nodeset = #{nodeset.inspect}"

        when :qname
          #puts "IN QNAME"
          prefix = path_stack.shift
          name = path_stack.shift
          default_ns = @namespaces[prefix]
          default_ns = default_ns ? default_ns : ''
          nodeset.delete_if do |node|
            ns = default_ns
            # FIXME: This DOUBLES the time XPath searches take
            ns = node.namespace( prefix ) if node.node_type == :element and ns == ''
            #puts "NS = #{ns.inspect}"
            #puts "node.node_type == :element => #{node.node_type == :element}"
            if node.node_type == :element
              #puts "node.name == #{name} => #{node.name == name}"
              if node.name == name
                #puts "node.namespace == #{ns.inspect} => #{node.namespace == ns}"
              end
            end
            !(node.node_type == :element and 
              node.name == name and 
              node.namespace == ns )
          end
          node_types = ELEMENTS

        when :any
          #puts "ANY 1: nodeset = #{nodeset.inspect}"
          #puts "ANY 1: node_types = #{node_types.inspect}"
          nodeset.delete_if { |node| !node_types.include?(node.node_type) }
          #puts "ANY 2: nodeset = #{nodeset.inspect}"

        when :self
          # This space left intentionally blank

        when :processing_instruction
          target = path_stack.shift
          nodeset.delete_if do |node|
            (node.node_type != :processing_instruction) or 
            ( target!='' and ( node.target != target ) )
          end

        when :text
          nodeset.delete_if { |node| node.node_type != :text }

        when :comment
          nodeset.delete_if { |node| node.node_type != :comment }

        when :node
          # This space left intentionally blank
          node_types = ALL

        when :child
          new_nodeset = []
          nt = nil
          for node in nodeset
            nt = node.node_type
            new_nodeset += node.children if nt == :element or nt == :document
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :literal
          literal = path_stack.shift
          if literal =~ /^\d+(\.\d+)?$/
            return ($1 ? literal.to_f : literal.to_i) 
          end
          return literal
        
        when :attribute
          new_nodeset = []
          case path_stack.shift
          when :qname
            prefix = path_stack.shift
            name = path_stack.shift
            for element in nodeset
              if element.node_type == :element
                #puts element.name
                attr = element.attribute( name, @namespaces[prefix] )
                new_nodeset << attr if attr
              end
            end
          when :any
            #puts "ANY"
            for element in nodeset
              if element.node_type == :element
                new_nodeset += element.attributes.to_a
              end
            end
          end
          nodeset = new_nodeset

        when :parent
          #puts "PARENT 1: nodeset = #{nodeset}"
          nodeset = nodeset.collect{|n| n.parent}.compact
          #nodeset = expr(path_stack.dclone, nodeset.collect{|n| n.parent}.compact)
          #puts "PARENT 2: nodeset = #{nodeset.inspect}"
          node_types = ELEMENTS

        when :ancestor
          new_nodeset = []
          for node in nodeset
            while node.parent
              node = node.parent
              new_nodeset << node unless new_nodeset.include? node
            end
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :ancestor_or_self
          new_nodeset = []
          for node in nodeset
            if node.node_type == :element
              new_nodeset << node
              while ( node.parent )
                node = node.parent
                new_nodeset << node unless new_nodeset.include? node
              end
            end
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :predicate
          new_nodeset = []
          subcontext = { :size => nodeset.size }
          pred = path_stack.shift
          nodeset.each_with_index { |node, index|
            subcontext[ :node ] = node
            #puts "PREDICATE SETTING CONTEXT INDEX TO #{index+1}"
            subcontext[ :index ] = index+1
            pc = pred.dclone
            #puts "#{node.hash}) Recursing with #{pred.inspect} and [#{node.inspect}]"
            result = expr( pc, [node], subcontext )
            result = result[0] if result.kind_of? Array and result.length == 1
            #puts "#{node.hash}) Result = #{result.inspect} (#{result.class.name})"
            if result.kind_of? Numeric
              #puts "Adding node #{node.inspect}" if result == (index+1)
              new_nodeset << node if result == (index+1)
            elsif result.instance_of? Array
              #puts "Adding node #{node.inspect}" if result.size > 0
              new_nodeset << node if result.size > 0
            else
              #puts "Adding node #{node.inspect}" if result
              new_nodeset << node if result
            end
          }
          #puts "New nodeset = #{new_nodeset.inspect}"
          #puts "Path_stack  = #{path_stack.inspect}"
          nodeset = new_nodeset
=begin
          predicate = path_stack.shift
          ns = nodeset.clone
          result = expr( predicate, ns )
          #puts "Result = #{result.inspect} (#{result.class.name})"
          #puts "nodeset = #{nodeset.inspect}"
          if result.kind_of? Array
            nodeset = result.zip(ns).collect{|m,n| n if m}.compact
          else
            nodeset = result ? nodeset : []
          end
          #puts "Outgoing NS = #{nodeset.inspect}"
=end

        when :descendant_or_self
          rv = descendant_or_self( path_stack, nodeset )
          path_stack.clear
          nodeset = rv
          node_types = ELEMENTS

        when :descendant
          results = []
          nt = nil
          for node in nodeset
            nt = node.node_type
            results += expr( path_stack.dclone.unshift( :descendant_or_self ),
              node.children ) if nt == :element or nt == :document
          end
          nodeset = results
          node_types = ELEMENTS

        when :following_sibling
          #puts "FOLLOWING_SIBLING 1: nodeset = #{nodeset}"
          results = []
          for node in nodeset
            all_siblings = node.parent.children
            current_index = all_siblings.index( node )
            following_siblings = all_siblings[ current_index+1 .. -1 ]
            results += expr( path_stack.dclone, following_siblings )
          end
          #puts "FOLLOWING_SIBLING 2: nodeset = #{nodeset}"
          nodeset = results

        when :preceding_sibling
          results = []
          for node in nodeset
            all_siblings = node.parent.children
            current_index = all_siblings.index( node )
            preceding_siblings = all_siblings[ 0 .. current_index-1 ].reverse
            #results += expr( path_stack.dclone, preceding_siblings )
          end
          nodeset = preceding_siblings
          node_types = ELEMENTS

        when :preceding
          new_nodeset = []
          for node in nodeset
            new_nodeset += preceding( node )
          end
          #puts "NEW NODESET => #{new_nodeset.inspect}"
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :following
          new_nodeset = []
          for node in nodeset
            new_nodeset += following( node )
          end
          nodeset = new_nodeset
          node_types = ELEMENTS

        when :namespace
          new_set = []
          for node in nodeset
            new_nodeset << node.namespace if node.node_type == :element or node.node_type == :attribute
          end
          nodeset = new_nodeset

        when :variable
          var_name = path_stack.shift
          return @variables[ var_name ]

        # :and, :or, :eq, :neq, :lt, :lteq, :gt, :gteq
        when :eq, :neq, :lt, :lteq, :gt, :gteq, :and, :or
          left = expr( path_stack.shift, nodeset, context )
          #puts "LEFT => #{left.inspect} (#{left.class.name})"
          right = expr( path_stack.shift, nodeset, context )
          #puts "RIGHT => #{right.inspect} (#{right.class.name})"
          res = equality_relational_compare( left, op, right )
          #puts "RES => #{res.inspect}"
          return res

        when :div
          left = Functions::number(expr(path_stack.shift, nodeset, context)).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context)).to_f
          return (left / right)

        when :mod
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left % right)

        when :mult
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left * right)

        when :plus
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left + right)

        when :minus
          left = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          right = Functions::number(expr(path_stack.shift, nodeset, context )).to_f
          return (left - right)

        when :union
          left = expr( path_stack.shift, nodeset, context )
          right = expr( path_stack.shift, nodeset, context )
          return (left | right)

        when :neg
          res = expr( path_stack, nodeset, context )
          return -(res.to_f)

        when :not
        when :function
          func_name = path_stack.shift.tr('-','_')
          arguments = path_stack.shift
          #puts "FUNCTION 0: #{func_name}(#{arguments.collect{|a|a.inspect}.join(', ')})" 
          subcontext = context ? nil : { :size => nodeset.size }

          res = []
          cont = context
          nodeset.each_with_index { |n, i| 
            if subcontext
              subcontext[:node]  = n
              subcontext[:index] = i
              cont = subcontext
            end
            arg_clone = arguments.dclone
            args = arg_clone.collect { |arg| 
              #puts "FUNCTION 1: Calling expr( #{arg.inspect}, [#{n.inspect}] )"
              expr( arg, [n], cont ) 
            }
            #puts "FUNCTION 2: #{func_name}(#{args.collect{|a|a.inspect}.join(', ')})" 
            Functions.context = cont
            res << Functions.send( func_name, *args )
            #puts "FUNCTION 3: #{res[-1].inspect}"
          }
          return res

        end
      end # while
      #puts "EXPR returning #{nodeset.inspect}"
      return nodeset
    end



  end
end


