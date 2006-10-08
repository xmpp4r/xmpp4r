# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/rexmladdons'

module Jabber
  ##
  # root class of all Jabber XML elements
  class XMPPElement < REXML::Element
    @@name_xmlns_classes = {}

    def self.name_xmlns(name, xmlns=nil)
      @@name_xmlns_classes[[name, xmlns]] = self
    end

    def self.name_xmlns_for_class(klass)
      klass.ancestors.each do |klass1|
        @@name_xmlns_classes.each do |name_xmlns,k|
          if klass1 == k
            return name_xmlns
          end
        end
      end

      raise "Class #{klass} has not set name and xmlns"
    end

    def self.class_for_name_xmlns(name, xmlns)
      if @@name_xmlns_classes.has_key? [name, xmlns]
        @@name_xmlns_classes[[name, xmlns]]
      elsif @@name_xmlns_classes.has_key? [name, nil]
        @@name_xmlns_classes[[name, nil]]
      else
        REXML::Element
      end
    end

    def self.import(element)
      klass = class_for_name_xmlns(element.name, element.namespace)
      if klass != self and klass.ancestors.include?(self)
        klass.new.import(element)
      else
        self.new.import(element)
      end
    end

    def initialize(force_xmlns=false)
      name, xmlns = self.class::name_xmlns_for_class(self.class)
      super(name)
      if force_xmlns
        add_namespace(xmlns)
      end
    end

    def typed_add(element)
      if element.kind_of? REXML::Element
        element_ns = (element.namespace.to_s == '') ? namespace : element.namespace

        klass = XMPPElement::class_for_name_xmlns(element.name, element_ns)
        if klass != element.class
          element = klass.import(element)
        end
      end

      super(element)
    end
  end
end
