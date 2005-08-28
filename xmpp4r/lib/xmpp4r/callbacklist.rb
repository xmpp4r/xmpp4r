# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/callback'

module Jabber
  ##
  # This exception is raised when no block is provided for the Callback
  class NoBlockError < RuntimeError
  end

  ##
  # This class manages a list of callbacks.
  #
  # ==Callbacks management and # priority
  #
  # Callbacks are managed by the class CallbackList. When they are added, a
  # priority (just a number or anything Comparable with other priorities) is
  # specified. The biggest the priority is, the earliest the callback will be
  # considered.
  #
  # Additionally, callbacks can "consume" elements. If a callback "consume" an
  # element, further Callbacks aren't considered. Rationale: some callbacks
  # need to be called only to "watch" elements (think of an "XML console"
  # feature) without blocking further callbacks from being considered.
  class CallbackList
  
    # create a new list of callbacks
    def initialize
      @list = []
    end

    ##
    # Add a callback to the list
    # prio:: [Integer] the callback's priority, the higher, the sooner.
    # ref:: [String] the callback's reference
    # proc:: [Proc] a proc to execute
    # block:: [Block] a block to execute
    # return:: [Jabber::CallbackList] The list, for chaining
    def add(prio, ref, proc = nil, &block)
      block = proc if proc
      raise NoBlockError, "Must supply a block or Proc object to the FilterList.add" + 
        " method" if block.nil?
      @list.push(Callback::new(prio, ref, block))
      @list.sort! { |a, b| b.priority <=> a.priority }
      self
    end

    ##
    # Delete a callback by reference
    # ref:: [String] the reference of the callback to delete
    # return:: [CallBackList] The list, for chaining
    def delete(ref)
      @list.delete_if { |item| item.ref == ref }
      self
    end

    ##
    # Number of elements in the list
    # return:: [Integer] The number of elements
    def length
      @list.length
    end

    ##
    # Process an element through all my callbacks. returns e.consumed?
    # e:: [XMLElement] The element to process
    # return:: [Boolean] true if the element has been consumed
    def process(e)
      # process through callbacks
      @list.each do |item|
        item.block.call(e)
        return true if e.consumed?
      end
      false
    end
  end
end
