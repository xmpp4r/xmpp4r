#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

require 'xmpp4r/xmlelement'

module Jabber
  ##
  # vCard container
  # (JEP 0054)
  class IqVcard < XMLElement
    ##
    # Initialize a <vCard/> element
    def initialize
      super("vCard")
      add_namespace('vcard-temp')
    end

    ##
    # xmlelement:: [REXML::Element] to import
    def IqVcard.import(xmlelement)
      IqVcard::new.import(xmlelement)
    end

    ##
    # Get an element
    #
    # vCards have too much possible children, so ask for them here
    # and extract the result with iqvcard.element('...').text
    # name:: [String] XPath
    def element(name)
      e = nil
      each_element(name) { |child| e = child }
      e
    end
  end
end
