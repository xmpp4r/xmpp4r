# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/
#
# ==Introduction
#
# XMPP4R is a XMPP/Jabber library for Ruby. It can be used to build scripts
# using Jabber, full-featured Jabber clients, and components. It is written
# with extensibility in mind.
#
# ==XML management
#
# All the XML parsing is REXML's, and XML stanzas like <message/> (class
# <tt>Jabber::Message</tt>) or <iq/> (class <tt>Jabber::Iq</tt>) are indirect
# derivatives from REXML's Element class. This provide a maximum flexibity :
# the user can access attributes and childs using either the XMPP4R's helpers
# or directly using REXML's methods.
#
# ==Threaded and non-threaded modes
#
# From the user point of view, the library can be used either in threaded mode,
# or in non-threaded mode, using a call to <tt>Jabber::Stream#process</tt> to
# receive pending messages.
#
# ==Where to begin?
#
# Because it is built in an extensible way, it might be hard for newcomers to
# understand where to look at documentation for a specific method. For example,
# Client heritates from Connection, which itself heritates from Stream.
#
# A newcomer should have a look at the <tt>Jabber::Client</tt> and
# <tt>Jabber::Component</tt> classes, and their parent classes
# <tt>Jabber::Connection</tt> and <tt>Jabber::Stream</tt>.  The best way to
# understand how to use them is probably to look at the examples in the
# <tt>examples/</tt> dir.

require 'xmpp4r/xmpp4r'
