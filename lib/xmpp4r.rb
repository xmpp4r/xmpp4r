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
# derivatives from REXML's Element class. This provide a maximum flexibity:
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
#
# ==Non-basic features
#
# <tt>require 'xmpp4r'</tt> does only include basic functionality as
# Connections, Authentication, Stream processing, Callbacks, Stanza handling
# and Debugging to keep the library's footprint small.
#
# There is code for features that aren't required by a *basic* client. These
# must be additionally included to use them.
#
# ===Protocol-level features
#
# You're highly advised to read the according RFCs and JEPs if you intend to
# use them. The benefit will be that you'll understand the protocols and are
# going to be more efficient when programming with them.
#
# * Jabber::IqQueryDiscoInfo, Jabber::DiscoIdentity, Jabber::DiscoFeature: <tt>require 'xmpp4r/iq/query/discoinfo'</tt>
# * Jabber::IqQueryDiscoItems, Jabber::DiscoItem: <tt>require 'xmpp4r/iq/query/discoitems'</tt>
# * Jabber::IqQueryRoster, Jabber::RosterItem: <tt>require 'xmpp4r/iq/query/roster'</tt>
# * Jabber::IqQueryVersion: <tt>require 'xmpp4r/iq/query/version'</tt>
# * Jabber::XDelay: <tt>require 'xmpp4r/x/delay'</tt>
# * Jabber::XMuc, Jabber::XMucUser: <tt>require 'xmpp4r/x/muc'</tt>
# * Jabber::XMucUserItem: <tt>require 'xmpp4r/x/mucuseritem'</tt>
#
# ===Helpers
#
# Helpers are intended to give more simplistic interfaces to various tasks
# of Jabber clients at the cost of flexibility. But you won't need that
# order of flexibility for the most things.
#
# * Jabber::Helpers::Version: <tt>require 'xmpp4r/helpers/version'</tt>
# * Jabber::Helpers::Roster: <tt>require 'xmpp4r/helpers/roster'</tt>

require 'xmpp4r/xmpp4r'
