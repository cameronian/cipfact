

module Cipfact
  class Keypair
    include Wrapper

    RSA_SENDER_INFO = 0x01
    ECC_SENDER_INFO = 0x02  

    def self.sender_info_from_int(int)
      case int
      when RSA_SENDER_INFO
        :rsa
      when ECC_SENDER_INFO
        :ecc
      else
        raise Error, "Unknown int value of '0x#{int.to_s(16)}' to convert sender info to"
      end
    end

    def self.sender_info_from_key(key)
      kkey = key.to_s.downcase.to_sym
      case kkey
      when :rsa
        RSA_SENDER_INFO
      when :ecc
        ECC_SENDER_INFO
      else
        raise Error, "Unknown key '#{key}' to convert sender info int value"
      end
    end

  end
end
