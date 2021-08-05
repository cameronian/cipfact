# frozen_string_literal: true

require 'toolrack'

require_relative "cipfact/version"
require_relative "cipfact/wrapper"
require_relative "cipfact/cipher"
require_relative "cipfact/keypair"
require_relative "cipfact/digest"
require_relative "cipfact/kdf"

require_relative "cipfact/input_memory"
require_relative "cipfact/input_file"

require_relative "cipfact/tag"
require_relative "cipfact/spec_dsl"

module Cipfact
  class Error < StandardError; end
  class CipherError < StandardError; end
  # Your code goes here...

  def self.instance(eng)
    Cipher.instance(eng)
  end

end
