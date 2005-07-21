module Jabber

  ##
  # The XMLElementFilter allows handlers to be triggered only for specific tags
  #
  class XMLElementFilter

    # The Filter's reference, using for deleting purposes
    attr_accessor :ref

    ##
    # Returns true if the |xe| matchs this filter
    # xe:: [XMLElement] The element to compare
    def match?(xe)
      return true
    end
  end
end
