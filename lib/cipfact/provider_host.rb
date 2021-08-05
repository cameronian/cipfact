

module Cipfact
  module ProviderHost
    include ToolRack::ConditionUtils
    class ProviderError < StandardError; end

    def register(prov)
      raise ProviderError, "Provider cannot be nil" if prov.nil?
      raise ProviderError, "Provider must have algo_name" if is_empty?(prov.algo_name)

      providers[prov.algo_name] = prov
    end

    def find(prov, *args, &block)
      ele = providers[prov]
      if not ele.nil?
        ele.send(:instance, *args, &block)
      end
    end

    def providers
      @providers = { } if @providers.nil?
      @providers
    end

  end
end
