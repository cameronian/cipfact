

module Cipfact
  class Cipher
    extend ToolRack::ConditionUtils

    def self.register(prov)
      raise Error, "Provider cannot be nil" if is_empty?(prov)
      raise Error, "Provider must have provider_name() method" if not prov.respond_to?(:provider_name)

      providers[prov.provider_name] = prov
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
