# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

module Jabber
  ##
  # The JID class represents a Jabber Identifier as described by 
  # RFC3920 section 3.1.
  #
  # Note that you can use JIDs also for Sorting, Hash keys, ...
  class JID
    include Comparable

    attr_reader :node, :domain, :resource

    PATTERN = /^(?:([^@]*)@)??([^@\/]+)(?:\/(.*?))?$/

    ##
    # Create a new JID. If called as new('a@b/c'), parse the string and
    # split (node, domain, resource)
    def initialize(node = nil, domain = nil, resource = nil)
      @resource = resource
      @domain = domain
      @node = node
      if domain.nil? and not node.nil?
        @node, @domain, @resource = node.to_s.scan(PATTERN).first
      end

      raise ArgumentError, 'Node too long' if @node.to_s.length > 1023
      raise ArgumentError, 'Domain too long' if @domain.to_s.length > 1023
      raise ArgumentError, 'Resource too long' if @resource.to_s.length > 1023
    end

    ##
    # Returns a string representation of the JID
    # * ""
    # * "domain"
    # * "node@domain"
    # * "domain/resource"
    # * "node@domain/resource"
    def to_s
      s = ''
      s = "#{@node}@" if not @node.nil?
      s += @domain if not @domain.nil?
      s += "/#{@resource}" if not @resource.nil?
      return s
    end

    ##
    # Returns a new JID with resource removed.
    # return:: [JID]
    def strip
      JID::new(@node, @domain)
    end
    alias_method :bare, :strip

    ##
    # No longer implemented. use strip instead !
    # return:: [JID] self
    def strip!
      raise "strip! is no longer implemented. use strip instead !"
    end

    ##
    # Returns a hash value of the String representation
    # (see JID#to_s)
    def hash
      return to_s.hash
    end

    ##
    # Ccompare to another JID
    #
    # String representations are compared, see JID#to_s
    def eql?(o)
      to_s.eql?(o.to_s)
    end

    ##
    # Compare two JIDs,
    # helpful for sorting etc.
    #
    # String representations are compared, see JID#to_s
    def <=>(o)
      to_s <=> o.to_s
    end
  end
end
