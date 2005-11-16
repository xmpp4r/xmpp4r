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

    ##
    # Create a new JID. If called as new('a@b/c'), parse the string and
    # split (node, domain, resource)
    def initialize(node = nil, domain = nil, resource = nil)
      if node.kind_of? JID
        @node = node.node
        @domain = node.domain
        @resource = node.resource
      else
        @resource = resource
        @domain = domain
        @node = node
        if domain.nil?
          if not node.nil?
            # node@domain/resource or domain/resource
            if node.include?('/')
              @domain, @resource = @node.split('/',2)
              # node@domain/resource
              if @domain.include?('@')
                @node, @domain = @domain.split('@', 2)
              # domain/resource
              else
                @node = nil
              end
            # node@domain
            elsif node.include?('@')
              @node, @domain = node.split('@', 2)
            # domain
            else
              @domain = node
              @node = nil
            end
          end
        end
      end
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

    ##
    # Remove the resource of *this* object
    # return:: [JID] self
    def strip!
      @resource = nil
      self
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
