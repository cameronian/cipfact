# frozen_string_literal: true

RSpec.describe Cipfact do
  it "has a version number" do
    expect(Cipfact::VERSION).not_to be nil
  end

  #it 'generates keypair' do
    #c = Cipfact.instance(:ruby)
    #expect(c).not_to be_nil

    #keys = []
    #keys << c.genkey(:rsa, 2048)
    #expect(keys.last).not_to be_nil
    #keys << c.genkey(:ecc)
    #expect(keys.last).not_to be_nil
    #keys << c.genkey(:aes, 256)
    #expect(keys.last).not_to be_nil

    #keys << c.deriveKey(:scrypt, "password") do |ops|
    #  case ops
    #  when :cost
    #  when :parallel
    #  end
    #end
    #expect(keys.last).not_to be_nil

    #data = "this is genuine message"
    #keys.each do |k|

    #  signed = c.detached_sign(data, rsaKp) 
    #  expect(signed).not_to be_nil
    #  st = c.verify(signed, pubKey) do |ops|
    #    case ops
    #    when :data
    #      # detached sign
    #      data
    #    end
    #  end
    #  expect(st).not_to be_nil
    #  expect(st).to be true

    #  st = c.verify(signed, pubKey) do |ops|
    #    case ops
    #    when :data
    #      # detached sign
    #      data+" "
    #    end
    #  end
    #  expect(st).not_to be_nil
    #  expect(st).to be false

    #end

    #signed = c.attached_sign(data, rsaKp) 
    #st = c.verify(signed, pubKey) 

    #c.encrypt(data, recipients)
    #c.decrypt(enc, kp)

  #end

end
