# frozen_string_literal: true

require 'cipfact/ruby'

RSpec.describe "Cipfact AES" do

  it 'generates AES signature and verify' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    key = cf.genkey(:aes, 256)
    expect(key).not_to be_nil

    c = cf.cipher(:aes)
    expect(c).not_to be_nil

    data = "genuine message"
    res = c.sign(data, key)
    expect(res).not_to be_nil

    expect{ c.sign(nil, nil) }.to raise_exception(Cipfact::CipherError)

    vres = c.verify({ sign: res, data: data }, key)
    expect(vres).not_to be_nil
    expect(vres).to be true

    vres2 = c.verify({ sign: res, data: "#{data} " }, key)
    expect(vres2).to be false

    res2 = c.sign(data, key) do |ops|
      case ops
      when :digest
        :sha512
      end
    end

    vres3 = c.verify({ sign: res2, data: data }, key)
    expect(vres3).to be true

  end

  it 'generates AES and perform encrypt and decrypt' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    key = cf.genkey(:aes, 256)
    expect(key).not_to be_nil

    c = cf.cipher(:aes)
    expect(c).not_to be_nil

    data = "genuine message"
    res = []
    enc = c.encrypt(data, key) do |ops, val|
      case ops
      when :encrypted
        res << val
      end
    end
    expect(enc).not_to be_nil

    plain = []
    dec = c.decrypt(res.join, key, enc) do |ops, val|
      case ops
      when :plain
        plain << val
      end
    end
    expect(plain.join == data).to be true
  end


end
