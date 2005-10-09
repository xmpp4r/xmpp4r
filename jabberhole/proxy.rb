require 'callbacks'  # from xmpp4r

##
# The Proxy module includes methods to expand and process CallbackLists
module Proxy
  @@client_cbs = CallbackList.new
  @@server_cbs = CallbackList.new

  def Proxy::add_client_callback(prio=0, &block)
    @@client_cbs.add(prio, nil, block)
  end

  def Proxy::add_server_callback(prio=0, &block)
    @@server_cbs.add(prio, nil, block)
  end

  def Proxy::process_client(stanza, clientserver)
    @@client_cbs.process(stanza, clientserver)
  end

  def Proxy::process_server(stanza, clientserver)
    @@server_cbs.process(stanza, clientserver)
  end
end
