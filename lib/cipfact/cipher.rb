

module Cipfact
  class Cipher
    extend ToolRack::ConditionUtils

    def self.register(prov)
      raise Error, "Provider cannot be nil" if is_empty?(prov)
      raise Error, "Provider must have provider_name() method" if not prov.respond_to?(:provider_name)

      pname = prov.provider_name
      if pname.is_a?(Array)
        pname.each do |pn|
          prov = providers[pn]
          raise Error, "Provider name '#{pn}' already taken and assigned to #{prov.class}" if not_empty?(prov)
          providers[pn] = prov
        end
      else
        providers[pname] = prov
      end

    end

    def self.instance(key)
      prov = providers[key]
      raise Error, "No provider for key '#{key}' found. Please make sure it is activated first." if prov.nil?
      prov
    end

    def self.providers
      @providers = { } if is_empty?(@providers)
      @providers
    end


  end
end
