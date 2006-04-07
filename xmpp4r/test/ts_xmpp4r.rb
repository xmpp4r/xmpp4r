#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'test')
$:.unshift File.join(File.dirname(__FILE__), 'lib')
$:.unshift File.join(File.dirname(__FILE__), 'test')

require 'tc_callbacks'
require 'tc_client'
require 'tc_error'
require 'tc_iqquery'
require 'tc_iqqueryroster'
require 'tc_iqqueryversion'
require 'tc_iq'
require 'tc_iqvcard'
require 'tc_jid'
require 'tc_message'
require 'tc_presence'
require 'tc_streamError'
require 'tc_stream'
require 'tc_streamSend'
require 'tc_streamThreaded'
require 'tc_xdelay'
require 'tc_xmlstanza'
require 'tc_helpers_mucclient'
