# =XMPP4R - XMPP Library for Ruby
#
# This file's copyright (c) 2009 by Pablo Lorenzzoni <pablo@propus.com.br>
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io
#
module Jabber
class Observable
  # Jabber::Observable::Contact - Convenience subclass to deal with Contacts
  class Contact

    # Creates a new Jabber::Observable::Contact
    #
    # jid:: jid to be used
    # observable:: observable to be used
    def initialize(jid, observable)
      @jid = jid.respond_to?(:resource) ? jid : JID.new(jid)
      @observable = observable
    end

    # Returns the stripped version of the JID
    def jid; @jid.strip; end

    def inspect #:nodoc:
      sprintf("#<%s:0x%x @jid=%s>", self.class.name, __id__, @jid.to_s)
    end

    # Are e subscribed?
    def subscribed?
      [:to, :both].include?(subscription)
    end

    # Get the subscription from the roster_item
    def subscription
      items = @observable.roster.items
      return false unless items.include?(jid)
      items[jid].subscription
    end

    # Send a request asking for authorization
    def ask_for_authorization!
      request!(:subscribe)
    end

    # Sends a request asking for unsubscription
    def unsubscribe!
      request!(:unsubscribe)
    end

    private

    # Really send the request.
    def request!(type)
      request = Jabber::Presence.new.set_type(type)
      request.to = jid
      @observable.send!(request)
    end

  end # of class Contact
end # of class Observable
end # of module Jabber
