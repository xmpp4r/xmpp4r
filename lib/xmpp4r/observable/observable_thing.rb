# =XMPP4R - XMPP Library for Ruby
#
# This file's copyright (c) 2009 by Pablo Lorenzzoni <pablo@propus.com.br>
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io
#
# This was based on Observable module from Ruby.
module ObservableThing
  require 'xmpp4r/observable/thread_store'

  # Adds an observer for some "thing".
  #
  # thing:: what will be observed.
  # observer:: the observer.
  # func:: the observer method that will be called (default: :update).
  def add_observer(thing, observer, func = :update)
    @things = {} unless defined? @things
    @things[thing] = {} unless ! @things[thing].nil?
    unless observer.respond_to? func
      raise NoMethodError, "observer does not respond to `#{func.to_s}'"
    end
    @things[thing][observer] = func unless @things[thing].include?(observer)
  end

  # Deletes an observer for some "thing".
  #
  # thing:: what has been observed.
  # observer:: the observer.
  def delete_observer(thing, observer)
    @things[thing].delete observer if defined? @things and ! @things[thing].nil?
  end

  # Delete observers for some "thing".
  #
  # thing:: what has been observed (if nil, deletes all observers).
  def delete_observers(thing = nil)
    if thing.nil?
      @things.clear if defined? @things
    else
      @things[thing].clear if defined? @things and ! @things[thing].nil?
    end
  end

  # Count the number of observers for some "thing".
  #
  # thing:: what has been observed (if nil, count all observers).
  def count_observers(thing = nil)
    return 0 if ! defined? @things
    size = 0
    if thing.nil?
      @things.each { |thing, hash|
        size += hash.size
      }
    else
      size = @things[thing].size unless @things[thing].nil?
    end
    size
  end

  # Count the number of notifications for some "thing".
  #
  # thing:: what has been observed.
  def count_notifications(thing)
    return 0 if (! defined?(@things_counter)) or (! @things_counter.include?(thing))
    @things_counter[thing]
  end

  # Change the state of some "thing".
  #
  # thing:: what will have the state changed.
  # state:: the state (default = true).
  def changed(thing, state = true)
    @things_state = {} unless defined? @things_state
    @things_state[thing] = state
  end

  # Check the state of some "thing".
  #
  # thing: what to have its state checked.
  def changed?(thing)
    if defined? @things_state and @things_state[thing]
      true
    else
      false
    end
  end

  # Notify all observers of "thing" about something. This will only be
  # enforced if the state of that "thing" is true. Also, if the observer
  # returns the Symbol :delete_me, it will be deleted after being notified.
  #
  # thing:: what has been observed.
  # args:: notification to be sent to the observers of "thing".
  def notify_observers(thing, *arg)
    if changed?(thing)
      if defined? @things and ! @things[thing].nil?
        @things[thing].each { |observer, func|
          increase_counter(thing)
          @thread_store = ThreadStore.new if ! defined? @thread_store
          @thread_store.add Thread.new {
            if observer.send(func, thing, *arg) == :delete_me
              delete_observer(thing, observer)
            end
          }
        }
      end
      changed(thing, false)
    end
  end

  # Is there pending notifications?
  def pending_notifications?
    return false if ! defined? @thread_store
    @thread_store.size > 0
  end

  # Wait all notifications
  def wait_notifications
    sleep 1 while pending_notifications?
  end

  private
  def increase_counter(thing)
    @things_counter = {} unless defined? @things_counter
    @things_counter[thing] = 0 unless @things_counter.include?(thing)
    @things_counter[thing] += 1
  end
end

# QObserver - simple observer-to-queue class
class QObserver
  require 'thread'

  def initialize
    @queues = Hash.new
  end

  def inspect
    h = {}
    @queues.each do |q, queue|
      h[q] = queue.size
    end
    if h.length > 0
      sprintf("#<%s:0x%x size=%s>", self.class.name, __id__, h.inspect)
    else
      sprintf("#<%s:0x%x>", self.class.name, __id__)
    end
  end  

  # Return the queues we have registered
  def queues
    @queues.keys
  end

  # Received something in this queue?
  #
  # q:: queue
  def received?(q)
    @queues.include?(q) and ! @queues[q].empty?
  end

  # Get the contents of the queue in an array (or pass each item to the
  # given block.
  #
  # q:: queue
  def received(q)
    return nil if ! @queues.include?(q)
    if block_given?
      yield @queues[q].deq while ! @queues[q].empty?
    else
      a = []
      a << @queues[q].deq while ! @queues[q].empty?
      return a
    end
  end

  # Get the size of a given queue
  #
  # q:: queue
  def size(q)
    @queues[q].size rescue 0
  end

  # update method for our Observer
  #
  # thing:: what to be updated
  def update(thing, *args)
    @queues[thing] = Queue.new if ! @queues.include?(thing)
    @queues[thing].enq args
  end
end
