#   XMPP4R - XMPP Library for Ruby
#   Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#   Released under GPL v2 or later
#
# ----
#
# =Introduction
#
# This library can be used to build Jabber clients and components, and is built
# for extensibility.
#
# =XML management
#
# All the XML parsing is REXML's, and XML stanzas like <message/> (class
# <em>Message</em>) or <iq/> (class <em>Iq</em>) are indirect derivatives from
# REXML's Element class. This provide a maximum flexibity : the user can access
# attributes and childs using either the library's helpers (<tt>set_to()</tt>
# for example) or directly using REXML's methods.
#
# =Threaded and non-threaded modes
#
# From the user point of view, the library can be used either in threaded mode,
# or in non-threaded mode, using a call to <tt>process()</tt> to receive
# pending messages.
#
# =Where to begin?
#
# Because it is built in an extensible way, it might be hard for newcomers to
# understand where to look at documentation for a specific method. For example,
# Client heritates from Connection, which itself heritates from Stream.
#
# A newcomer should have a look at the <em>Client</em> and <em>Component</em>
# classes, and their parent classes <em>Connection</em> and <em>Stream</em>.
# The best way to understand how to use them is probably to look at the
# examples in the <tt>examples/</tt> dir.

##
# The Jabber module is the root namespace of the library
module Jabber
  VERSION_MAJOR = 0
  VERSION_MINOR = 1
  DEBUG = false
end

require "xmpp4r/xmpp4r.rb"
