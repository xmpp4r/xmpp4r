# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

module Jabber
  ##
  # The AuthenticationFailure is an Exception to be raised
  # when Client or Component authentication fails
  #
  # There are no special arguments
  class AuthenticationFailure < RuntimeError
  end
end
