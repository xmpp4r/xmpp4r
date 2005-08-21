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
    # fields:: [Hash] Initialize with keys as XPath element names and values for element texts
    def initialize(fields=nil)
      super("vCard")
      add_namespace('vcard-temp')

      unless fields.nil?
        fields.each { |name,value|
          self[name] = value
        }
      end
    end

    ##
    # xmlelement:: [REXML::Element] to import
    def IqVcard.import(xmlelement)
      IqVcard::new.import(xmlelement)
    end

    ##
    # Get an elements/fields text
    #
    # vCards have too much possible children, so ask for them here
    # and extract the result with iqvcard.element('...').text
    # name:: [String] XPath
    def [](name)
      text = nil
      each_element(name) { |child| text = child.text }
      text
    end

    ##
    # Set an elements/fields text
    # name:: [String] XPath
    # text:: [String] Value
    def []=(name, text)
      xe = self
      name.split(/\//).each do |elementname|
        # Does the children already exist?
        newxe = nil
        xe.each_element(elementname) { |child| newxe = child }

        if newxe.nil?
          # Create a new
          xe = xe.add_element(elementname)
        else
          # Or take existing
          xe = newxe
        end
      end
      xe.text = text
    end

    ##
    # Get vCard field names
    #
    # Recursed two levels at maximum
    # result:: [Array] of [String]
    def fields
      names = []
      each_element { |e|
        if e.text.to_s.chomp != ''
          names.push(e.name)
        end

        if e.kind_of?(REXML::Element)
          e.each_element { |child|
            names.push("#{e.name}/#{child.name}")
          }
        end
      }
      names.uniq
    end
  end
end
