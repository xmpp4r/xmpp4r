#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'test')
$:.unshift File.join(File.dirname(__FILE__), 'lib')
$:.unshift File.join(File.dirname(__FILE__), 'test')

require 'xmpp4r'
require 'tc_callbacks'
require 'tc_client'
require 'tc_iq'
require 'tc_jid'
require 'tc_message'
require 'tc_streamError'
require 'tc_stream'
require 'tc_streamSend'
require 'tc_streamThreaded'
require 'tc_xmlstanza'
