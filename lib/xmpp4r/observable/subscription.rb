# =XMPP4R - XMPP Library for Ruby
#
# This file's copyright (c) 2009 by Pablo Lorenzzoni <pablo@propus.com.br>
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io
module Jabber
class Observable
  # Jabber::Observable::Subscriptions - convenience class to deal with
  # Presence subscriptions
  #
  # observable:: points to a Jabber::Observable object
  class Subscriptions
    def initialize(observable)
      @observable = observable
      @accept = true
    end

    # Ask the users specified by jids for authorization (i.e., ask them to add
    # you to their contact list), unless already in the contact list.
    #
    # Because the authorization process depends on the other user accepting your
    # request, results are notified to observers of :new_subscription.
    def add(*jids)
      @observable.contacts(*jids).each do |contact|
        next if subscribed_to?(contact)
        contact.ask_for_authorization!
      end
    end

    # Remove the jabber users specified by jids from the contact list.
    def remove(*jids)
      @observable.contacts(*jids).each do |contact|
        contact.unsubscribe!
      end
    end

    # Returns true if this Jabber account is subscribed to status updates for
    # the jabber user jid, false otherwise.
    def subscribed_to?(jid)
      @observable.contacts(jid).each do |contact|
        return contact.subscribed?
      end
    end

    # Returns true if auto-accept subscriptions is enabled (default), false otherwise.
    def accept?
      @accept
    end

    # Change whether or not subscriptions are automatically accepted.
    def accept=(accept_status)
      @accept = accept_status
    end
  end # of class Subscription
end # of class Observable
end # of module Jabber

