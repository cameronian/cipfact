
require_relative "provider_host"

module Cipfact
  class Digest
    extend ToolRack::ConditionUtils
    extend Cipfact::ProviderHost

    class DigestError < StandardError; end

    # convert user input to constant defined in Tag
    def self.engine_from_user_to_tag(user)
      case user
      when :sha1, :sha160
        :sha1
      when :sha2, :sha256
        :sha256
      when :sha3, :sha384
        :sha384
      when :sha5, :sha512
        :sha512
      else
        raise DigestError, "Unknown key '#{user}' for digest engine" 
      end
    end

    def self.tag_to_engine(tag)
      case tag
      when 0x1001
        :sha1
      when 0x1002
        :sha256
      when 0x1003
        :sha384
      when 0x1005
        :sha512
      end
    end

  end
end
