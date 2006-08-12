# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/query'

module Jabber
  module RPC
    class IqQueryRPC < IqQuery
      NS_RPC = 'jabber:iq:rpc'
      ##
      # creates a new namespace stanza
      def initialize
         super
         add_namespace('jabber:iq:rpc')
      end

      def typed_add(e)
        if e.kind_of? String
          typed_add(REXML::Document.new(e))
        else
          super
        end
      end
    end

    IqQuery.add_namespaceclass(IqQueryRPC::NS_RPC, IqQueryRPC)
  end
end

