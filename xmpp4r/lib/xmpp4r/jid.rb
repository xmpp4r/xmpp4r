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

    PATTERN = /^(?:([^@]*)@)??([^@\/]+)(?:\/(.*?))?$/

    begin
      require 'idn'
      USE_STRINGPREP = true
    rescue LoadError
      USE_STRINGPREP = false
    end

    ##
    # Create a new JID. If called as new('a@b/c'), parse the string and
    # split (node, domain, resource)
    def initialize(node = "", domain = "", resource = "")
      @resource = resource.to_s
      @domain = domain.to_s
      @node = node.to_s
      if @domain.empty? and not @node.empty?
        @node, @domain, @resource = @node.scan(PATTERN).first
      end

      if USE_STRINGPREP
        @node = IDN::Stringprep.nodeprep(@node)
        @domain = IDN::Stringprep.nameprep(@domain)
        @resource = IDN::Stringprep.resourceprep(@resource)
      end

      raise ArgumentError, 'Node too long' if @node.length > 1023
      raise ArgumentError, 'Domain too long' if @domain.length > 1023
      raise ArgumentError, 'Resource too long' if @resource.length > 1023
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
      s = "#{@node}@" if not @node.empty?
      s += @domain if not @domain.empty?
      s += "/#{@resource}" if not @resource.empty?
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
      @resource = ""
    end
    alias_method :bare!, :strip!

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

    # Get the JID's node
    def node
      return nil if @node.empty?
      @node
    end

    # Set the JID's node
    def node=(v)
      @node = v.to_s
      if USE_STRINGPREP
        @node = IDN::Stringprep.nodeprep(@node) if @node
      end
    end

    # Get the JID's domain
    def domain
      return nil if @domain.empty?
      @domain
    end

    # Set the JID's domain
    def domain=(v)
      @domain = v.to_s
      if USE_STRINGPREP
        @domain = IDN::Stringprep.nodeprep(@domain)
      end
    end

    # Get the JID's resource
    def resource
      return nil if @resource.empty?
      @resource
    end

    # Set the JID's resource
    def resource=(v)
      @resource = v.to_s
      if USE_STRINGPREP
        @resource = IDN::Stringprep.nodeprep(@resource)
      end
    end

    # Escape JID
    def JID::escape(jid)
      return jid.to_s.gsub('@', '%')
    end
  end
end
