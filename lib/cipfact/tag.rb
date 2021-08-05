
require 'tlogger'

module Cipfact

  class TagException < StandardError; end

  class Tag
    extend ToolRack::ExceptionUtils

    REGISTRY = {}
    CONSTANT = {}

    def initialize(&block)
      @parentTag = []
      @definedTag = {}
      @logger = Tlogger.new
      instance_eval(&block)
    end

    def self.tag(key)
      if REGISTRY[key].nil?
        res = CONSTANT[key]
      else
        res = REGISTRY[key][:const]
      end
      raise_if_empty(res, "Value with key #{key} not found")
      res
    end

    def self.value(key)
      tag(key)
    end

    def self.constant(key)
      CONSTANT[key]
    end

    def self.constant_key(val)
      CONSTANT.invert[val]
    end
    
    def self.text(key)
      REGISTRY[key] == nil ? nil : REGISTRY[key][:text]
    end

    def add_constant(key,val)
      if CONSTANT.keys.include?(key)
        raise TagException, "Constant already have key '#{key}' defined"
      end

      CONSTANT[key] = val
    end

    def register(key, const, text, &block)
      if const =~ /#parent/
        const.gsub!("#parent",@parentTag[-1])
      end
      add_to_registry(key, { const: const, text: text })
    end

    def parent(key, val, text = "", &block) 
      if val =~ /#parent/
        val.gsub!("#parent",@parentTag[-1])
      end

      add_to_registry(key, { const: val, text: text })

      @parentTag.push(val)
      instance_eval(&block)
      @parentTag.pop
    end

    def add_to_registry(key,val)
      if not REGISTRY[key].nil?
        STDERR.puts "Key #{key} already defined and tied to value #{REGISTRY[key]}."
        raise TagException, "Key #{key} already defined and tied to value #{REGISTRY[key]}."
      else
        constCheck = @definedTag[val[:const]]
        if not constCheck.nil?
          STDERR.puts "Constant #{val[:const]} already defined and mapped to key #{constCheck}"
          raise TagException, "Constant #{val[:const]} already defined and mapped to key #{constCheck}"
        else
          @definedTag[val[:const]] = key
          REGISTRY[key] = val
          CONSTANT[val[:const]] = key

          #@logger.debug "#{key} / #{val} added to registry"
        end
      end
    end

  end
end

include Cipfact

# 
# DSL to construct the Tag tree
#
Tag.new do

  parent(:root, '2.8.198.1.1', "Cipfact Root OID") do

    parent(:encoder_id, "#parent.0") do 
      register(:ruby_encoder, "#parent.1", "Default Ruby encoding engine")
    end

    parent(:kdf, "#parent.1", "Key Derivation Formula") do
      parent(:kdf_scrypt, "#parent.1", "KDF Scrypt") do
      end
    end

    parent(:digest, "#parent.2", "Digest Hashing") do
      add_constant(:sha1,   0x1001)
      add_constant(:sha256, 0x1002)
      add_constant(:sha384, 0x1003)
      add_constant(:sha512, 0x1005)
    end

    parent(:symkey, "#parent.3", "Symmetric key output") do
      register(:aes_signature, "#parent.1", "AES signature output")
      register(:aes_cipher_config, "#parent.2", "AES key cipher config (header)")  # only header describe the cipher config, without the encrypted data
      register(:aes_key, "#parent.3", "AES key. Contains the key value")
    end

    parent(:asymkey,"#parent.4", "Asymmetric key output") do
      register(:rsa_signature, "#parent.1", "RSA signature output")
      register(:rsa_cipher, "#parent.2", "RSA cipher")
      register(:rsa_hybrid_cipher, "#parent.3", "RSA hybrid cipher")

      register(:ecc_cipher, "#parent.5", "ECC ECIES cipher")

      parent(:sender_info, "#parent.10", "Sender info") do
        register(:sender_info_public_key, "#parent.1", "Public key sender info")
        register(:sender_info_x509, "#parent.2", "X509 certificate sender info")
      end
    end

  end 

end

if $0 == __FILE__
  Tag::REGISTRY.each do |k,v|
    puts "#{k} : #{v}"
  end
end
