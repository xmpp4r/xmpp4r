# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iqquery'

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
      delete_elements('name')
      add_element('name').text = (text.nil? ? '' : text)
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
      text = nil
      each_element('os') { |os| text = os.text }
      text
    end

    ##
    # Set the os of the software
    def os=(text)
      set_os(text)
    end

    def set_os(text)
      if text
        replace_element_text('os', text)
      else
        delete_elements('os')
      end
      self
    end
  end

  IqQuery.add_namespace('jabber:iq:version', IqQueryVersion)
end

