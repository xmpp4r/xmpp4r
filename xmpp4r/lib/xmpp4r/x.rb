#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

require 'xmpp4r/xmlelement'

module Jabber
  ##
  # A class used to build/parse <x/> elements
  #
  class X < REXML::Element
    @@namespace_classes = {}

    ##
    # Initialize a <x/> element
    #
    # Does nothing more than setting the element's name to 'x'
    def initialize
      super("x")
    end

    ##
    # Create a new [X] from an XML-Element
    # xmlelement:: [REXML::Element] to import, will be automatically converted if namespace appropriate
    def X.import(xmlelement)
      if @@namespace_classes.has_key?(xmlelement.namespace)
        @@namespace_classes[xmlelement.namespace]::new.import(xmlelement)
      else
        X::new.import(xmlelement)
      end
    end

    ##
    # Add a class by namespace for automatic X conversion (see X.import)
    # ns:: [String] Namespace (e.g. 'jabber:x:delay')
    # xclass:: [X] x class derived from X
    def X.add_namespaceclass(ns, xclass)
      @@namespace_classes[ns] = xclass
    end
  end
end
