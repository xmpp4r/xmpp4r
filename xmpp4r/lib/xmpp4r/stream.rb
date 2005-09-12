# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'callbacks'
require 'socket'
require 'thread'
Thread::abort_on_exception = true
require 'xmpp4r/streamparser'
require 'xmpp4r/presence'
require 'xmpp4r/message'
require 'xmpp4r/iq'
require 'xmpp4r/debuglog'

module Jabber
  ##
  # The stream class manages a connection stream (a file descriptor using which
  # XML messages are read and sent)
  class Stream
    DISCONNECTED = 1
    CONNECTED = 2

    # file descriptor used
    attr_reader :fd

    # connection status
    attr_reader :status

    ##
    # Create a new stream
    # (just initializes)
    def initialize(threaded = true)
      @fd = nil
      @status = DISCONNECTED
      @xmlcbs = CallbackList::new
      @stanzacbs = CallbackList::new
      @messagecbs = CallbackList::new
      @iqcbs = CallbackList::new
      @presencecbs = CallbackList::new
      @threaded = threaded
      @StanzaQueue = []
      @StanzaQueueMutex = Mutex::new
      @threadBlocks = {}
#      @pollCounter = 10
      @waitingThread = nil
      @wakeupThread = nil
      @streamid = nil
    end

    ##
    # Start the XML parser on the fd
    def start(fd)
      @fd = fd
      @parser = StreamParser.new(@fd, self)
      @parserThread = Thread.new {
        begin
        @parser.parse
        rescue
          puts "Exception caught in Parser thread, dumping backtrace and" +
            " exiting...\n" + $!.exception + "\n"
          puts $!.backtrace
          exit
        end
      }
#      @pollThread = Thread.new do
#        begin
#        poll
#        rescue
#          puts "Exception caught in Poll thread, dumping backtrace and" +
#            " exiting...\n" + $!.exception + "\n"
#          puts $!.backtrace
#          exit
#        end
#      end
      @status = CONNECTED
    end

    ##
    # Mounts a block to handle exceptions if they occur during the 
    # poll send.  This will likely be the first indication that
    # the socket dropped in a Jabber Session.
    #
    def on_exception(&block)
      @exception_block = block
    end

    ##
    # This method is called by the parser when a failure occurs
    def parse_failure
      # A new thread has to be created because close will cause the thread
      # to commit suicide
      if @exception_block
        Thread.new { @exception_block.call }
      else
        puts "Stream#parse_failure was called by XML parser. Dumping " +
        "backtrace and exiting...\n" + $!.exception + "\n"
        puts $!.backtrace
      end
      close
    end

    ##
    # Returns if this connection is connected to a Jabber service
    # return:: [Boolean] Connection status
    def is_connected?
      return @status == CONNECTED
    end

    ##
    # Returns if this connection is NOT connected to a Jabber service
    #
    # return:: [Boolean] Connection status
    def is_disconnected?
      return @status == DISCONNECTED
    end

    ##
    # Processes a received REXML::Element and executes 
    # registered thread blocks and filters against it.
    #
    # element:: [REXML::Element] The received element
    def receive(element)
      Jabber::debuglog("RECEIVED:\n#{element.to_s}")
      case element.name
      when 'stream'
        stanza = element
      	i = element.attribute("id")
        @streamid = i.value if i
      when 'message'
        stanza = Message::import(element)
      when 'iq'
        stanza = Iq::import(element)
      when 'presence'
        stanza = Presence::import(element)
      else
        stanza = element
      end
      # Iterate through blocked theads (= waiting for an answer)
      @threadBlocks.each { |thread, proc|
        r = proc.call(stanza)
        if r == true
          @threadBlocks.delete(thread)
          thread.wakeup if thread.alive?
          return
        end
      }
      if @threaded
        process_one(stanza)
      else
        # StanzaQueue will be read when the user call process
        @StanzaQueueMutex.lock
        @StanzaQueue.push(stanza)
        @StanzaQueueMutex.unlock
        @waitingThread.wakeup if @waitingThread
      end
    end

    ##
    # Process |element| until it is consumed. Returns element.consumed?
    # element  The element to process
    def process_one(stanza)
      Jabber::debuglog("PROCESSING:\n#{stanza.to_s}")
      return true if @xmlcbs.process(stanza)
      return true if @stanzacbs.process(stanza)
      case stanza
      when Message
        return true if @messagecbs.process(stanza)
      when Iq
        return true if @iqcbs.process(stanza)
      when Presence
        return true if @presencecbs.process(stanza)
      end
    end
    private :process_one

    ##
    # Process |max| XML stanzas and call listeners for all of them. 
    #
    # max:: [Integer] the number of stanzas to process (nil means process
    # all available)
    def process(max = nil)
      n = 0
      @StanzaQueueMutex.lock
      while @StanzaQueue.size > 0 and (max == nil or n < max)
        e = @StanzaQueue.shift
        @StanzaQueueMutex.unlock
        process_one(e)
        n += 1
        @StanzaQueueMutex.lock
      end
      @StanzaQueueMutex.unlock
      n
    end

    ##
    # Process an XML stanza and call the listeners for it. If no stanza is
    # currently available, wait for max |time| seconds before returning.
    # 
    # time:: [Integer] time to wait in seconds. If nil, wait infinitely.
    # all available)
    def wait_and_process(time = nil)
      if time == 0 
        return process(1)
      end
      @StanzaQueueMutex.lock
      if @StanzaQueue.size > 0
        e = @StanzaQueue.shift
        @StanzaQueueMutex.unlock
        process_one(e)
        return 1
      end

      @waitingThread = Thread.current
      @wakeupThread = Thread.new { sleep time ; @waitingThread.wakeup if @waitingThread }
      @waitingThread.stop
      @wakeupThread.kill if @wakeupThread
      @wakeupThread = nil
      @waitingThread = nil

      @StanzaQueueMutex.lock
      if @StanzaQueue.size > 0
        e = @StanzaQueue.shift
        @StanzaQueueMutex.unlock
        process_one(e)
        return 1
      end
      return 0
    end

    ##
    # Sends XML data to the socket and (optionally) waits
    # to process received data.
    #
    # xml:: [String] The xml data to send
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    def send(xml, proc=nil, &block)
      Jabber::debuglog("SENDING:\n#{ xml.kind_of?(String) ? xml : xml.to_s }")
      xml = xml.to_s if not xml.kind_of? String
      block = proc if proc
      @threadBlocks[Thread.current]=block if block
      Thread.critical = true # we don't want to be interupted before we stop!
      begin
        @fd << xml
        @fd.flush
      rescue
        if @exception_block 
          @exception_block.call
        else
          puts "Exception caught while sending, dumping backtrace and" +
            " exiting...\n" + $!.exception + "\n"
          puts $!.backtrace
          exit(1)
        end
      end
      Thread.stop if block
      @pollCounter = 10
    end

    ##
    # Starts a polling thread to send "keep alive" data to prevent
    # the Jabber connection from closing for inactivity.
    def poll
      sleep 10
      while true
        sleep 2
#        @pollCounter = @pollCounter - 1
#        if @pollCounter < 0
#          begin
#            send("  \t  ")
#          rescue
#            Thread.new {@exception_block.call if @exception_block}
#            break
#          end
#        end
      end
    end

    ##
    # Adds a callback block/proc to process received XML messages
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    def add_xml_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @xmlcbs.add(priority, ref, block)
    end

    ##
    # Delete an XML-messages callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_xml_callback(ref)
      @xmlcbs.delete(ref)
    end

    ##
    # Adds a callback block/proc to process received Messages
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    def add_message_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @messagecbs.add(priority, ref, block)
    end

    ##
    # Delete an Message callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_message_callback(ref)
      @messagecbs.delete(ref)
    end

    ##
    # Adds a callback block/proc to process received Stanzas
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    def add_stanza_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @stanzacbs.add(priority, ref, block)
    end

    ##
    # Delete a Stanza callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_stanza_callback(ref)
      @stanzacbs.delete(ref)
    end
    
    ##
    # Adds a callback block/proc to process received Presences 
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    def add_presence_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @presencecbs.add(priority, ref, block)
    end

    ##
    # Delete a Presence callback
    #
    # ref:: [String] The reference of the callback to delete
    def delete_presence_callback(ref)
      @presencecbs.delete(ref)
    end
    
    ##
    # Adds a callback block/proc to process received Iqs
    # 
    # priority:: [Integer] The callback's priority, the higher, the sooner
    # ref:: [String] The callback's reference 
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    def add_iq_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @iqcbs.add(priority, ref, block)
    end

    ##
    # Delete an Iq callback
    #
    # ref:: [String] The reference of the callback to delete
    #
    def delete_iq_callback(ref)
      @iqcbs.delete(ref)
    end
    ##
    # Closes the connection to the Jabber service
    def close
      @parserThread.kill if @parserThread
#      @pollThread.kill
      @fd.close if @fd
      @status = DISCONNECTED
    end
  end
end
