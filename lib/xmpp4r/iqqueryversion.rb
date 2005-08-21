#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

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
    def initialize(iname=nil, version=nil, os=nil)
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
      text = nil
      each_element('name') { |name| text = name.text }
      text
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
      text = nil
      each_element('version') { |version| text = version.text }
      text
    end

    ##
    # Set the version of the software
    #
    # The element won't be deleted if text is nil as
    # it must occur in a version query
    def version=(text)
      delete_elements('version')
      add_element('version').text = text.nil? ? '' : text
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
      delete_elements('os')
      add_element('os').text = text unless text.nil?
    end

    def set_os(text)
      self.os = text
      self
    end
  end

  IqQuery.add_namespace('jabber:iq:version', IqQueryVersion)
end

