# frozen_string_literal: true

require 'cipfact/ruby'

RSpec.describe "Cipfact ECC" do
  it "has a version number" do
    expect(Cipfact::VERSION).not_to be nil
  end

  it 'generates ECC keypair and native sign & verify operations' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    kp = cf.genkey(:ecc, "prime256v1")
    expect(kp).not_to be_nil

    data = "this is genuine message"
    c = cf.cipher(:ecc)
    expect(c).not_to be_nil

    res = c.sign(data, kp)
    expect(res).not_to be_nil
    
    vres = c.verify({ sign: res, data: data }, kp.public_key)
    expect(vres).to be true

  end

  it 'generates ECC keypair and native encrypt & decrypt operations' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    kp = cf.genkey(:ecc, "prime256v1")
    expect(kp).not_to be_nil

    data = "this is genuine message"
    c = cf.cipher(:ecc)
    expect(c).not_to be_nil

    enc = []
    res = c.encrypt_init(kp.public_key, { senderPrivKey: kp }) do |eng|
      eng.encrypt_update(data) do |ops, val|
        case ops
        when :encrypted
          enc << val
        end
      end
    end
    expect(res).not_to be_nil

    plain = []
    c.decrypt_init(kp, res) do |eng|
      eng.decrypt_update(enc.join) do |ops, val|
        case ops
        when :plain
          plain << val
        end
      end
    end
    p plain.join

  end


end
