# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
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
      each_element(e) { |el| return el }
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
          add(e.deep_clone)
        else
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
end


