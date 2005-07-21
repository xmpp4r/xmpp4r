#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#  Released under GPL v2 or later

module Jabber
  ##
  # This class is constructed from XML data elements that are received from
  # the Jabber service.
  #
  class ParsedXMLElement  

    ##
    # This class is used to return nil element values to prevent errors (and
    # reduce the number of checks.
    #
    class NilParsedXMLElement

      ##
      # Override to return nil
      #
      # return:: [nil]
      #
      def method_missing(methId, *args)
        return nil
      end

      ##
      # Evaluate as nil
      #
      # return:: [Boolean] true
      #
      def nil?
        return true
      end

      ##
      # Return a zero count
      #
      # return:: [Integer] 0
      #
      def count
        0
      end

      include Singleton
    end

    # The <tag> as String
    attr_reader :element_tag

    # The parent ParsedXMLElement
    attr_reader :element_parent

    # A hash of ParsedXMLElement children
    attr_reader :element_children

    # The data <tag>data</tag> for a tag
    attr_reader :element_data

    ##
    # Construct an instance for the given tag
    #
    # tag:: [String] The tag
    # parent:: [Jabber::Protocol::ParsedXMLElement = nil] The parent element
    #
    def initialize(tag, parent=nil)
      @element_tag = tag
      @element_parent = parent
      @element_children = {}
      @attr = {}
      @element_consumed = false
    end

    ##
    # Add the attribute to the element
    #   <tag name="value">data</tag>
    # 
    # name:: [String] The attribute name
    # value:: [String] The attribute value
    # return:: [Jabber::Protocol::ParsedXMLElement] self for chaining
    #
    def add_attr(name, value)
      @attr[name]=value
      self
    end

    ##
    # Get the specified attribute
    # 
    # name:: [String] The attribute name
    # return:: [String] The attribute value
    #
    def get_attr(name)
      if @attr.include?(name)
        return @attr[name]
      else
        return nil
      end 
    end

    ##
    # Factory to build a child element from this element with the given tag
    #
    # tag:: [String] The tag name
    # return:: [Jabber::Protocol::ParsedXMLElement] The newly created child element
    #
    def add_child(tag)
      child = ParsedXMLElement.new(tag, self)
      @element_children[tag] = Array.new if not @element_children.has_key? tag
      @element_children[tag] << child
      return child
    end

    ##
    # When an xml is received from the Jabber service and a ParsedXMLElement is created,
    # it is propogated to all filters and listeners.  Any one of those can consume the element 
    # to prevent its propogation to other filters or listeners. This method marks the element
    # as consumed.
    #
    def consume_element
      @element_consumed = true
    end

    ##
    # Checks if the element is consumed
    #
    # return:: [Boolean] True if the element is consumed
    #
    def element_consumed?
      @element_consumed
    end

    ##
    # Appends data to the element
    #
    # data:: [String] The data to append
    # return:: [Jabber::Protocol::ParsedXMLElement] self for chaining
    #
    def append_data(data)
      @element_data = "" unless @element_data
      @element_data += data
      self
    end

    ##
    # Calls the parent's element_children (hash) index off of this elements
    # tag and gets the supplied index.  In this sense it gets its sibling based
    # on offset.
    #
    # number:: [Integer] The number of the sibling to get
    # return:: [Jabber::Protocol::ParsedXMLElement] The sibling element
    #
    def [](number)
      return @element_parent.element_children[@element_tag][number] if @element_parent
    end

    ##
    # Returns the count of siblings with this element's tag
    #
    # return:: [Integer] The number of sibling elements
    #
    def count
      return @element_parent.element_children[@element_tag].size if @element_parent
      return 0
    end

    ##
    # see _count
    #
    def size
      count
    end

    ##
    # Overrides to allow for directly accessing child elements
    # and attributes.  If prefaced by attr_ it looks for an attribute
    # that matches or checks for a child with a tag that matches
    # the method name.  If no match occurs, it returns a 
    # NilParsedXMLElement (singleton) instance.
    # 
    # Example:: <alpha number="1"><beta number="2">Beta Data</beta></alpha>
    #
    #  element.element_tag #=> alpha
    #  element.attr_number #=> 1
    #  element.beta.element_data #=> Beta Data
    #
    def method_missing(methId, *args)
      tag = methId.id2name
      if tag[0..4]=="attr_"
        return @attr[tag[5..-1]]
      end
      list = @element_children[tag]
      return list[0] if list
      return NilParsedXMLElement.instance
    end  

    ##
    # Returns the valid XML as a string
    #
    # return:: [String] XML string
    def to_s
      begin
        result = "\n<#{@element_tag}"
        @attr.each {|key, value| result += (' '+key+'"'+value+'"') }
        if @element_children.size>0 or @element_data
          result += ">"
        else
          result += "/>" 
        end
        result += @element_data if @element_data
        @element_children.each_value {|array| array.each {|je| result += je.to_s} }
        result += "\n" if @element_children.size>0
        result += "</#{@element_tag}>" if @element_children.size>0 or @element_data
        result
      rescue => exception
        puts exception.to_s
      end
    end
  end
end
