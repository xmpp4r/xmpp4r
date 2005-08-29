# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'rexml/document'
require 'xmpp4r/xmlstanza'
require 'xmpp4r/jid'
require 'xmpp4r/error'
require 'xmpp4r/iqquery.rb'
require 'xmpp4r/iqvcard.rb'
require 'digest/sha1'

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
    # Get the type of the Iq stanza
    #
    # The following values are allowed:
    # * :get
    # * :set
    # * :result
    # * :error
    # result:: [Symbol] or nil
    def type
      case attributes['type']
        when 'get' then :get
        when 'set' then :set
        when 'result' then :result
        when 'error' then :error
        else nil
      end
    end

    ##
    # Set the type of the Iq stanza (see type)
    # v:: [Symbol] or nil
    def type=(v)
      case v
        when :get then attributes['type'] = 'get'
        when :set then attributes['type'] = 'set'
        when :result then attributes['type'] = 'result'
        when :error then attributes['type'] = 'error'
        else attributes['type'] = nil
      end
    end

    ##
    # Set the type of the Iq stanza (chaining-friendly)
    # v:: [Symbol] or nil
    def set_type(v)
      self.type = v
      self
    end

    ##
    # Returns the iq's query child, or nil
    # result:: [IqQuery]
    def query 
      first_element('query')
    end

    ##
    # Delete old elements named newquery.name
    #
    # newquery:: [REXML::Element] will be added
    def query=(newquery)
      delete_elements(newquery.name)
      add(newquery)
    end

    ##
    # Returns the iq's query's namespace, or nil
    # result:: [String]
    def queryns 
      e = first_element('query')
      if e
        return e.namespace
      else
        return nil
      end
    end

    ##
    # Returns the iq's <vCard/> child, or nil
    # result:: [IqVcard]
    def vcard 
      first_element('vCard')
    end

    ##
    # Create a new iq from a stanza
    def Iq.import(xmlstanza)
      Iq::new.import(xmlstanza)
    end

    ##
    # Add an element to the Iq stanza
    # xmlelement:: [REXML::Element] Element to add.
    # * <query/> elements will be converted to [IqQuery]
    # * <vCard/> elements will be converted to [IqVcard]
    # * <error/> elements will be converted to [Error]
    def add(xmlelement)
      if xmlelement.kind_of?(REXML::Element) && (xmlelement.name == 'query')
        super(IqQuery::import(xmlelement))
      elsif xmlelement.kind_of?(REXML::Element) && (xmlelement.name == 'vCard') && (xmlelement.namespace == 'vcard-temp')
        super(IqVcard::import(xmlelement))
      elsif xmlelement.kind_of?(REXML::Element) && (xmlelement.name == 'error')
        super(Error::import(xmlelement))
      else
        super(xmlelement)
      end
    end

    ##
    # Create a new Iq stanza with a query child
    def Iq.new_query(type = nil, to = nil)
      iq = Iq::new(type, to)
      query = IqQuery::new
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:auth set Stanza.
    def Iq.new_authset(jid, password)
      iq = Iq::new(:set)
      query = IqQuery::new
      query.add_namespace('jabber:iq:auth')
      query.add(REXML::Element::new('username').add_text(jid.node))
      query.add(REXML::Element::new('password').add_text(password))
      query.add(REXML::Element::new('resource').add_text(jid.resource)) if not jid.resource.nil?
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:auth set Stanza for Digest authentication
    def Iq.new_authset_digest(jid, session_id, password)
      iq = Iq::new(:set)
      query = IqQuery::new
      query.add_namespace('jabber:iq:auth')
      query.add(REXML::Element::new('username').add_text(jid.node))
      query.add(REXML::Element::new('digest').add_text(Digest::SHA1.new(session_id + password).hexdigest))
      query.add(REXML::Element::new('resource').add_text(jid.resource)) if not jid.resource.nil?
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster get Stanza.
    #
    # IqQueryRoster is unused here because possibly not require'd
    def Iq.new_rosterget
      iq = Iq::new(:get)
      query = IqQuery::new
      query.add_namespace('jabber:iq:roster')
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster get Stanza.
    def Iq.new_browseget
      iq = Iq::new(:get)
      query = IqQuery::new
      query.add_namespace('jabber:iq:browse')
      iq.add(query)
      iq
    end

    ##
    # Create a new jabber:iq:roster set Stanza.
    def Iq.new_rosterset
      iq = Iq::new(:set)
      query = IqQuery::new
      query.add_namespace('jabber:iq:roster')
      iq.add(query)
      iq
    end

    ##
    # Create a new Iq stanza with a vCard child
    # type:: [String] or "get" if omitted
    def Iq.new_vcard(type = :get, to = nil)
      iq = Iq::new(type, to)
      iq.add(IqVcard::new)
      iq
    end
  end
end
