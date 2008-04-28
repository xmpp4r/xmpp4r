require 'xmpp4r/framework/base'

require 'xmpp4r/roster'
require 'xmpp4r/discovery'
require 'xmpp4r/xhtml'

module Jabber
  module Framework
    ##
    # Abstract handler methods that *may* be implemented by a deriving class:
    # * on_message(text)
    # * on_message_xhtml(html_body, text)
    class Bot < Base
      helper :roster, Roster::Helper
      helper :disco_caps { |cl|
        Discovery::Responder.new(cl,
                                 "http://home.gna.org/xmpp4r/##{Jabber::XMPP4R_VERSION}",
                                 [Jabber::Discovery::Identity.new('client', 'XMPP4R Bot', 'bot')],
                                 ['message', 'presence', Caps::NS_CAPS]
                                 )
      }

      def initialize(jid, password)
        cl = Jabber::Client::new(jid)
        cl.connect
        cl.auth(password)

        super(cl)

        cl.add_message_callback do |msg|
          if msg.type != :error and msg.body
            if (html = msg.first_element('html')) and respond_to? :on_message_xhtml
              on_message_xhtml(html.body, msg.body)
            elsif respond_to? :on_message
              on_message(msg.body)
            end
          end
        end

        add_cap('message') if respond_to? :on_message
        add_cap(XHTML::NS_XHTML_IM) if respond_to? :on_message_xhtml

        @presence_show = nil
        @presence_status = nil
      end

      def add_cap(capability)
        disco_caps.add_feature(capability)
      end

      ##
      # Send a simple text chat message
      def send_message(to, text)
        msg = Message.new
        msg.type = :chat
        msg.to = to
        msg.body = text
        @stream.send(msg)
      end

      ##
      # Send an XHTML chat message
      # text:: [String] alternate plain text body, generated from xhtml_contents if nil
      def send_message_xhtml(to, xhtml_contents, text=nil)
        msg = Message.new
        msg.type = :chat
        msg.to = to
        html = msg.add(XHTML::HTML.new(xhtml_contents))
        msg.body = text ? text : html.to_text
        @stream.send(msg)
      end

      def set_presence(show=nil, status=nil)
        @presence_show = show
        @presence_status = status
        send_presence
      end

      private

      def send_presence
        roster.wait_for_roster

        # TODO: vcard photo hash
        presence = Presence.new(@presence_show, @presence_status)
        presence.add(disco_caps.generate_caps)
        @stream.send(presence)
      end
    end

  end
end
