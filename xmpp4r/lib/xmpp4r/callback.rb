# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

module Jabber
  # This class is used to store callbacks inside CallbackList. See the
  # CallbackList class for more detailed explanations.
  class Callback

    # The Callback's priority
    attr_reader :priority

    # The Callback's reference, using for deleting purposes
    attr_reader :ref

    # The Callback's block to execute 
    attr_reader :block

    ##
    # Create a new callback
    # priority:: [Integer] the callback's priority. The higher, the sooner it
    #            will be executed
    # ref:: [String] The callback's reference
    def initialize(priority = 0, ref = nil, block = Proc::new {})
      @priority = priority
      @ref = ref
      @block = block
    end
  end
end
