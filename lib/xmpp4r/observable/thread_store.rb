# =XMPP4R - XMPP Library for Ruby
#
# This file's copyright (c) 2009 by Pablo Lorenzzoni <pablo@propus.com.br>
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io
#
# Class ThreadStore
class ThreadStore
  attr_reader :cycles, :max

  # Create a new ThreadStore.
  #
  # max:: max number of threads to store (when exhausted, older threads will
  # just be killed and discarded). Default is 100. If 0 or negative no
  # threads will be discarded until #keep is called.
  def initialize(max = 100)
    @store  = []
    @max    = max > 0 ? max : 0
    @cycles = 0
    @killer_thread = Thread.new do
      loop do
        sleep 2 while @store.empty?
        sleep 1
        @store.each_with_index do |thread, i|
          th = @store.delete_at(i) if thread.nil? or ! thread.alive?
          th = nil
        end
        @cycles += 1
      end
    end
  end

  def inspect # :nodoc:
    sprintf("#<%s:0x%x @max=%d, @size=%d @cycles=%d>", self.class.name, __id__, @max, size, @cycles)
  end

  # Add a new thread to the ThreadStore
  def add(thread)
    if thread.instance_of?(Thread) and thread.respond_to?(:alive?)
      @store << thread
      keep(@max) if @max > 0
    end
  end

  # Keep only the number passed of threads
  #
  # n:: number of threads to keep (default to @max if @max > 0)
  def keep(n = nil)
    if n.nil?
      raise ArgumentError, "You need to pass the number of threads to keep!" if @max == 0
      n = @max
    end
    @store.shift.kill while @store.length > n
  end

  # Kill all threads
  def kill!
    @store.shift.kill while @store.length > 0
  end

  # How long is our ThreadStore
  def size; @store.length; end

end # of class ThreadStore

