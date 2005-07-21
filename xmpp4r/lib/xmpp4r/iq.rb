#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#  Released under GPL v2 or later

require 'rexml/document'
require 'xmpp4r/xmlstanza'
require 'xmpp4r/jid'
include REXML

module Jabber
  ##
  # A class used to build/parse IQ requests/responses
  #
  class Iq < XMLStanza
    def initialize(type = nil, to = nil)
      super("iq")
      if not to.nil?
        set_to(to)
      end 
      if not type.nil?
        set_type(type)
      end 
    end

    ##
    # Returns the iq's query child, or nil
    def query 
      s = nil
      each_element('query') { |e| s = e if s.nil? }
      s
    end

    ##
    # Returns the iq's query's namespace, or nil
    def queryns 
      s = nil
      each_element('query') { |e| s = e.namespace if s.nil? }
      s
    end

    ##
    # Create a new iq from a stanza
    def Iq.import(xmlstanza)
      # TODO : clean up. The should be a better way.
      Iq::new.import(xmlstanza)
    end

    ##
    # Create a new jabber:iq:auth set Stanza.
    def Iq.new_authset(jid, password)
      iq = Iq::new('set')
      query = Element::new('query')
      query.add_namespace('jabber:iq:auth')
      query.add(Element::new('username').add_text(jid.node))
      query.add(Element::new('password').add_text(password))
      query.add(Element::new('resource').add_text(jid.resource)) if not jid.resource.nil?
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster get Stanza.
    def Iq.new_rosterget
      iq = Iq::new('get')
      query = Element::new('query')
      query.add_namespace('jabber:iq:roster')
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster get Stanza.
    def Iq.new_browseget
      iq = Iq::new('get')
      query = Element::new('query')
      query.add_namespace('jabber:iq:browse')
      iq.add(query)
      iq
    end
    ##
    # Create a new jabber:iq:roster set Stanza.
    def Iq.new_rosterset
      iq = Iq::new('set')
      query = Element::new('query')
      query.add_namespace('jabber:iq:roster')
      iq.add(query)
      iq
    end
  end
end
