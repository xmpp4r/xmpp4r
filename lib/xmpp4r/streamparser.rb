# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

module Jabber
  require 'rexml/document'
  require 'rexml/parsers/sax2parser'
  require 'rexml/source'
  require 'xmpp4r/xmlelement'

  ##
  # The REXMLJabberParser uses REXML to parse the incoming XML stream
  # of the Jabber protocol and fires XMLElements at the Connection
  # instance.
  #
  class StreamParser
    # status if the parser is started
    attr_reader :started

    ##
    # Constructs a parser for the supplied stream (socket input)
    #
    # stream:: [IO] Socket input stream
    # listener:: [Object.receive(XMLElement)] The listener (usually a Jabber::Protocol::Connection instance
    #
    def initialize(stream, listener)
      @stream = stream
      # this hack fixes REXML version "2.7.3"
      if REXML::Version=="2.7.3"
        def @stream.read(len=nil)
          len = 100 unless len
          super(len)
        end
      end
      @listener = listener
      @current = nil
    end

    ##
    # Begins parsing the XML stream and does not return until
    # the stream closes.
    #
    def parse
      @started = false
      begin
        parser = REXML::Parsers::SAX2Parser.new @stream 
        parser.listen( :start_element ) do |uri, localname, qname, attributes|
          if @current.nil?
            @current = XMLElement::new(qname)
          else
            e = XMLElement::new(qname)
            @current = @current.add_element(e)
          end
          @current.add_attributes attributes
          if @current.name == 'stream'
            @listener.receive(@current)
            @started = true
          end
        end
        parser.listen( :end_element ) do  |uri, localname, qname|
          case qname
          when "stream:stream"
            @started = false
          else
            @listener.receive(@current) if @current.parent.name == 'stream'
            @current = @current.parent
          end
        end
        parser.listen( :characters ) do | text |
          @current.text = (@current.text.nil? ? '' : @current.text) + text
        end
        parser.listen( :cdata ) do | text |
          raise "Not implemented !"
        end
        parser.parse
      rescue REXML::ParseException
        @listener.parse_failure
      end
    end
  end
end
