# frozen_string_literal: true

require 'cipfact/ruby'

RSpec.describe "Cipfact RSA" do
  it "has a version number" do
    expect(Cipfact::VERSION).not_to be nil
  end

  it 'generates RSA keypair and native sign & verify operations' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    kp = cf.genkey(:rsa, 2048)
    expect(kp).not_to be_nil

    data = "this is genuine message"
    c = cf.cipher(:rsa_native)
    expect(c).not_to be_nil

    res = c.sign(data,kp)
    expect(res).not_to be_nil
    
    vres = c.verify({ sign: res, data: data, pubKey: kp.public_key })
    expect(vres).to be true

    res = c.sign(data, kp) do |ops|
      case ops
      when :pss_mode?
        false
      end
    end
    expect(res).not_to be_nil

    vres = c.verify({ sign: res, data: data, pubKey: kp.public_key })
    expect(vres).to be true

    res = c.sign(data, kp) do |ops|
      case ops
      when :signHash
        :sha3
      when :saltLength
        48
      when :mgf1Hash
        :sha5
      end
    end
    expect(res).not_to be_nil

    vres = c.verify({ sign: res, data: data, pubKey: kp.public_key })
    expect(vres).to be true

    vres = c.verify({ sign: res, data: data })
    expect(vres).to be true

  end

  it 'generates RSA keypair and native encrypt & decrypt operations' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    kp = cf.genkey(:rsa, 2048)
    expect(kp).not_to be_nil

    data = "this is genuine message"
    c = cf.cipher(:rsa_native)
    expect(c).not_to be_nil

    enc = c.encrypt(data, kp.public_key)
    expect(enc).not_to be_nil

    plain = c.decrypt(enc, kp)
    expect(plain == data).to be true

    enc[50] = 'S'
    expect{ c.decrypt(enc, kp) }.to raise_exception(Cipfact::CipherError)

    #res = c.encrypt_init(kp.public_key) do |eng|
    #  File.open('../../../Luna-SSL-Testing.7z',"rb") do |f|
    #    eng.encrypt_update(f.read)
    #  end
    #end
    #p res

  end


end
