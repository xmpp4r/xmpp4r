module Jabber
  module MUC
    class IqQueryMucOwner < IqQuery
      name_xmlns 'query', 'http://jabber.org/protocol/muc#owner'
      
      def x(wanted_xmlns=nil)
        if wanted_xmlns.kind_of? XMPPElement
          wanted_xmlns = wanted_xmlns.new.namespace
        end

        each_element('x') { |x|
          if wanted_xmlns.nil? or wanted_xmlns == x.namespace
            return x
          end
        }
        nil
      end
    end
  end
end
