# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

##
# The Jabber module is the root namespace of the library. You might want
# to Include it in your script to ease your coding. It provides
# a simple debug logging support.
module Jabber
  # XMPP4R Version number
  XMPP4R_VERSION = '0.1'

  # Is debugging mode enabled ?
  @@debug = false

  # Enable/disable debugging mode
  def Jabber::debug=(debug)
    @@debug = debug
    if @@debug
      debuglog('Debugging mode enabled.')
    end
  end

  # returns true if debugging mode is enabled.
  def Jabber::debug
    @@debug
  end
    
  # Outputs a string only if debugging mode is enabled. If the string includes
  # several lines, 4 spaces are added at the begginning of each line but the
  # first one. Time is prepended to the string.
  def Jabber::debuglog(string)
    return if not @@debug
    s = string.chomp.gsub("\n", "\n    ")
    t = Time::new.strftime('%H:%M:%S')
    puts "#{t} #{s}"
  end
end

require 'xmpp4r/message'
require 'xmpp4r/iq'
require 'xmpp4r/presence'
require 'xmpp4r/client'
require 'xmpp4r/component'
