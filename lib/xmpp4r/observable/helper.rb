# =XMPP4R - XMPP Library for Ruby
#
# This file's copyright (c) 2009 by Pablo Lorenzzoni <pablo@propus.com.br>
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io
#
# This is the helper for xmpp4r/observable, and was based on XMPP4R-Observable
# by Pablo Lorenzoni <pablo@propus.com.br>.
require 'time'
require 'xmpp4r'
require 'xmpp4r/roster'
require 'xmpp4r/observable/contact'
require 'xmpp4r/observable/pubsub'
require 'xmpp4r/observable/subscription'
module Jabber

class NotConnected < StandardError; end #:nodoc:

# Jabber::Observable - Creates observable Jabber Clients
class Observable

  # This is what actually makes our object Observable.
  include ObservableThing

  attr_reader :subs, :pubsub, :jid, :auto

  # Create a new Jabber::Observable client. You will be automatically connected
  # to the Jabber server and your status message will be set to the string
  # passed in as the status_message argument.
  #
  # jabber = Jabber::Observable.new("me@example.com", "password", nil, "Talk to me - Please!")
  #
  # jid:: your jid (either a string or a JID object)
  # password:: your password
  # status:: your status. Check Jabber::Observable#status for documentation
  # status_message:: some funny string
  # host:: the server host (if different from the one in the jid)
  # port:: the server port (default: 5222)
  def initialize(jid, password, status=nil, status_message="Available", host=nil, port=5222)

    # Basic stuff
    @jid = jid.respond_to?(:resource) ? jid : Jabber::JID.new(jid)
    @password = password
    @host = host
    @port = port

    # Message dealing
    @delivered_messages = 0
    @deferred_messages = Queue.new
    start_deferred_delivery_thread

    # Connection stuff
    @connect_mutex = Mutex.new
    @client = nil
    @roster = nil
    @disconnected = false

    # Tell everybody I am here
    status(status, status_message)

    # Subscription Accessor
    @subs = Jabber::Observable::Subscriptions.new(self)

    # PubSub Accessor
    @pubsub = Jabber::Observable::PubSub.new(self)

    # Auto Observer placeholder
    @auto = nil

    # Our contacts Hash
    @contacts = Hash.new
  end

  def inspect # :nodoc:
    sprintf("#<%s:0x%x @jid=%s, @delivered_messages=%d, @deferred_messages=%d, @observer_count=%s, @notification_count=%s, @pubsub=%s>", self.class.name, __id__, @jid, @delivered_messages, @deferred_messages.length, observer_count.inspect, notification_count.inspect, @pubsub.inspect)
  end

  # Count the registered observers in each thing
  def observer_count
    h = {}
    [ :message, :presence, :iq, :new_subscription, :subscription_request, :event ].each do |thing|
      h[thing] = count_observers(thing)
    end
    h
  end

  # Count the notifications really sent for each thing
  def notification_count
    h = {}
    [ :message, :presence, :iq, :new_subscription, :subscription_request, :event ].each do |thing|
      h[thing] = count_notifications(thing)
    end
    h
  end

  # Attach an auto-observer based on QObserver
  def attach_auto_observer
    raise StandardError, "Already attached." unless @auto.nil?

    @auto = QObserver.new
    [ :message, :presence, :iq, :new_subscription, :subscription_request, :event ].each do |thing|
      self.add_observer(thing, @auto)
    end
  end

  # Dettach the auto-observer
  def dettach_auto_observer
    raise StandardError, "Not attached." if @auto.nil?

    [ :message, :presence, :iq, :new_subscription, :subscription_request, :event ].each do |thing|
      self.delete_observer(thing, @auto)
    end
    @auto = nil
  end

  # Send a message to jabber user jid.
  #
  # jid:: jid of the recipient
  # message:: what is to be delivered (either a string or a Jabber::Message)
  # type:: can be either one of:
  #   * :normal: a normal message.
  #   * :chat (default): a one-to-one chat message.
  #   * :groupchat: a group-chat message.
  #   * :headline: a "headline" message.
  #   * :error: an error message.
  #
  # If the recipient is not in your contacts list, the message will be queued
  # for later delivery, and the Contact will be automatically asked for
  # authorization (see Jabber::Observable#add).
  def deliver(jid, message, type=nil)
    contacts(jid).each do |contact|
      # Check if we're subscribed to contact
      if @subs.subscribed_to?(contact)
        # Yes! we are!
        if message.instance_of?(Jabber::Message)
          msg = message
          msg.to = contact.jid
          msg.type = type unless type.nil?   # Let's keep the Jabber::Message type unless passed
        else
          msg = Jabber::Message.new(contact.jid)
          msg.body = message
          msg.type = type.nil? ? :chat : type
        end
        @delivered_messages += 1
        send!(msg)
      else
        # No... Let's add it and defer the delivery.
        @subs.add(contact.jid)
        deliver_deferred(contact.jid, message, type)
      end
    end
  end

  # Set your presence, with a message.
  #
  # presence:: any of these:
  #   * nil: online.
  #   * :chat: free for chat.
  #   * :away: away from the computer.
  #   * :dnd: do not disturb.
  #   * :xa: extended away.
  # message:: a string that you wish your contacts see when you change your presence.
  def status(presence, message)
    @status_message = message
    @presence = presence
    send!(Jabber::Presence.new(@presence, @status_message))
  end

  # Transform a passed list of contacts in one or more Jabber::Observable::Contact objects.
  #
  # contact:: one of more jids of contacts
  def contacts(*contact)
    ret = []
    contact.each do |c|
      jid = c.to_s
      # Do we already have it?
      if ! @contacts.include?(jid)
        # Nope.
        @contacts[jid] = c.instance_of?(Jabber::Observable::Contact) ? c : Jabber::Observable::Contact.new(c, self)
      end
      ret << @contacts[jid]
    end
    ret
  end

  # Returns true if the Jabber client is connected to the Jabber server,
  # false otherwise.
  def connected?
    @client.respond_to?(:is_connected?) && @client.is_connected?
  end

  # Pass the underlying Roster helper.
  def roster
    return @roster unless @roster.nil?
    @roster = Jabber::Roster::Helper.new(client)
  end

  # Pass the underlying Jabber client.
  def client
    connect! unless connected?
    @client
  end

  # Send a Jabber stanza over-the-wire.
  #
  # msg:: the stanza to be sent.
  def send!(msg)
    retries = 0
    max = 4
    begin
      retries += 1
      client.send(msg)
    rescue Errno::ECONNRESET => e
      # Connection reset. Sleep progressively and retry until success or exhaustion.
      sleep ((retries^2) * 60) + 30
      disconnect
      reconnect
      retry unless retries > max
      raise e
    rescue Errno::EPIPE, IOError => e
      # Some minor error. Sleep 2 seconds and retry until success or exhaustion.
      sleep 2
      disconnect
      reconnect
      retry unless retries > max
      raise e
    end
  end

  # Use this to force the client to reconnect after a disconnect.
  def reconnect
    @disconnected = false
    connect!
  end

  # Use this to force the client to disconnect and not automatically
  # reconnect.
  def disconnect
    disconnect!(false)
  end

  # Queue messages for delivery once a user has accepted our authorization
  # request. Works in conjunction with the deferred delivery thread.
  #
  # You can use this method if you want to manually add friends and still
  # have the message queued for later delivery.
  def deliver_deferred(jid, message, type)
    msg = {:to => jid, :message => message, :type => type, :time => Time.now}
    @deferred_messages.enq msg
  end

  # Sets the maximum time to wait for a message to be delivered (in
  # seconds). It will be removed of the queue afterwards.
  def deferred_max_wait=(seconds)
    @deferred_max_wait = seconds
  end

  # Get the maximum time to wait for a message to be delivered. Default: 600
  # seconds (10 minutes).
  def deferred_max_wait
    @deferred_max_wait || 600
  end

  private

  # Create the infrastructure for connection and do it.
  #
  # Note that we use a Mutex to prevent double connection attempts and will
  # raise a SecurityError if that happens.
  def connect!
    raise RuntimeError, "Connections disabled - use Jabber::Observable::reconnect() to reconnect." if @disconnected
    raise SecurityError, "Connection attempt while already trying to connect!" if @connect_mutex.locked?

    @connect_mutex.synchronize do
      # Assure we're not connected.
      disconnect!(false) if connected?

      # Connection
      jid = Jabber::JID.new(@jid)
      my_client = Jabber::Client.new(jid)
      my_client.connect(@host, @port)
      my_client.auth(@password)
      @roster = nil
      @client = my_client

      # Post-connect
      register_default_callbacks
      status(@presence, @status_message)
      if @pubsub.nil?
        @pubsub = Jabber::Observable::PubSub.new(self)
      else
        @pubsub.attach!
      end
    end
  end

  # Really disconnect the client
  #
  # auto_reconnect:: Sets the flag for auto-reconnection
  def disconnect!(auto_reconnect = true)
    if connected?
      client.close
    end
    @roster = nil
    @client = nil
    @pubsub.set_service(nil)
    @disconnected = auto_reconnect
  end

  # This will register callbacks for every "thing" we made observable.
  #
  # The observable things we register here are :message, :presence, :iq,
  # :new_subscription, and :subscription_request
  #
  # Note we can also observe :event, but that is dealt with in
  # Jabber::Observable::PubSub
  def register_default_callbacks

    # The three basic "things": :message, :presence and :iq
    # (note that :presence is based on roster)
    client.add_message_callback do |message|
      unless message.body.nil?
        changed(:message)
        notify_observers(:message, message)
      end
    end

    roster.add_presence_callback do |roster_item, old_presence, new_presence|
      simple_jid = roster_item.jid.strip.to_s
      presence = case new_presence.type
                 when nil then new_presence.show || :online
                 when :unavailable then :unavailable
                 else
                   nil
                 end

      changed(:presence)
      notify_observers(:presence, simple_jid, presence, new_presence)
    end

    client.add_iq_callback do |iq|
      changed(:iq)
      notify_observers(:iq, iq)
    end

    # We'll also expose roster's :new_subscription and :subscription_request
    roster.add_subscription_callback do |roster_item, presence|
      if presence.type == :subscribed
        changed(:new_subscription)
        notify_observers(:new_subscription, [roster_item, presence])
      end
    end

    roster.add_subscription_request_callback do |roster_item, presence|
      roster.accept_subscription(presence.from) if @subs.accept?
      changed(:subscription_request)
      notify_observers(:subscription_request, [roster_item, presence])
    end
  end

  # Starts the deferred delivery thread
  #
  # This will monitor the @deferred_messages queue and try to deliver messages.
  def start_deferred_delivery_thread
    return if ! @deferred_delivery_thread.nil? and @deferred_delivery_thread.alive?

    @deferred_delivery_thread = Thread.new do
      loop do 
        # Check the queue every 10 seconds. Effectivelly block if nothing is queued.
        sleep 10 while @deferred_messages.empty?

        # Hm... something has been queued
        message = @deferred_messages.deq
        if @subs.subscribed_to?(message[:to])
          # Great! We're subscribed!
          deliver(message[:to], message[:message], message[:type])
        else
          # Still not subscribed. Enqueue it again (unless deferred_max_wait was reached)
          @deferred_messages.enq message unless Time.now > (deferred_max_wait + message[:time])
        end

        # Wait 5 seconds between every message still in the queue
        sleep 5
      end
    end
  end
end # of class Observable
end # of module Jabber

