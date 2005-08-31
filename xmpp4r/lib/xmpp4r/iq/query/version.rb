# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq/query'

module Jabber
  ##
  # Class for handling queries for 'Software Version'
  # (JEP 0092)
  #
  # Notice that according to JEP 0092 only the <os/> element can be omitted,
  # <name/> (iname) and <version/> must be present
  class IqQueryVersion < IqQuery
    ##
    # Create a new <query xmlns='jabber:iq:version'/>
    def initialize(iname='', version='', os=nil)
      super()
      add_namespace('jabber:iq:version')
      set_iname(iname)
      set_version(version)
      set_os(os)
    end

    ##
    # Import an element,
    # deletes <name/>, <version/> and <os/> elements first
    # xe:: [REXML::Element]
    def import(xe)
      delete_element('name')
      delete_element('version')
      delete_element('os')
      super
    end

    ##
    # Get the name of the software
    #
    # This has been renamed to 'iname' here to keep
    # REXML::Element#name accessible
    def iname
      first_element_text('name')
    end

    ##
    # Set the name of the software
    #
    # The element won't be deleted if text is nil as
    # it must occur in a version query
    def iname=(text)
      replace_element_text('name', text)
    end

    def set_iname(text)
      self.iname = text
      self
    end

    ##
    # Get the version of the software
    def version
      first_element_text('version')
    end

    ##
    # Set the version of the software
    #
    # The element won't be deleted if text is nil as
    # it must occur in a version query
    def version=(text)
      replace_element_text('version', text)
    end

    def set_version(text)
      self.version = text
      self
    end

    ##
    # Get the operating system
    def os
      first_element_text('os')
    end

    ##
    # Set the os of the software
    def os=(text)
      if text
        replace_element_text('os', text)
      else
        delete_elements('os')
      end
    end

    def set_os(text)
      self.os = text
      self
    end
  end

  IqQuery.add_namespaceclass('jabber:iq:version', IqQueryVersion)
end

