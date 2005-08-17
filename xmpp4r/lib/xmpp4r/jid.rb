#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#  Released under GPL v2 or later

module Jabber
  ##
  # The JID class represents a Jabber Identifier as described by 
  # RFC3920 section 3.1.
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
            if node.include?('@')
              @node, @domain = node.split('@',2)
              if @domain.include?('/')
                @domain, @resource = @domain.split('/',2)
              end
            elsif node.include?('/')
              @domain, @resource = @node.split('/',2)
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
    def to_s
      s = ''
      s = "#{@node}@" if not @node.nil?
      s += @domain if not @domain.nil?
      s += "/#{@resource}" if not @resource.nil?
      return s
    end

    ##
    # Returns a new JID with resource removed.
    def strip
      JID::new(@node, @domain)
    end

    ##
    # Remove the resource
    def strip!
      @resource = nil
      self
    end

    def <=>(o)
      to_s <=> o.to_s
    end
  end
end
