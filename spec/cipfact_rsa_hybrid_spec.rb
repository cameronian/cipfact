# frozen_string_literal: true

require 'cipfact/ruby'

RSpec.describe "Cipfact RSA Hybrid" do

  it 'generates RSA keypair and native sign & verify operations' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    kp = cf.genkey(:rsa, 2048)
    expect(kp).not_to be_nil

    data = "this is genuine message"
    c = cf.cipher(:rsa_hybrid)
    expect(c).not_to be_nil

    res = c.sign(data,kp)
    expect(res).not_to be_nil
    
    vres = c.verify({ sign: res, data: data, pubKey: kp.public_key } )
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
    c = cf.cipher(:rsa_hybrid)
    expect(c).not_to be_nil

    enc = c.encrypt(data, kp.public_key)
    expect(enc).not_to be_nil

    plain = c.decrypt(enc, kp)
    expect(plain == data).to be true

    enc[50] = 'S'
    expect{ c.decrypt(enc, kp) }.to raise_exception(Cipfact::CipherError)

    dig = cf.digest_eng(:sha256)
    encCont = []
    dig.digest_init
    res = c.encrypt_init(kp.public_key) do |eng|
      File.open('../../../Luna-SSL-Testing.7z',"rb") do |f|
        eng.encrypt_update(f.read) do |ops, val|
          case ops
          when :encrypted
            encCont << val
          when :plain
            dig.digest_update(val)
          end
        end
      end
    end
    digRes = dig.digest_final

    dig.digest_init 
    encContIo = StringIO.new(encCont.join)
    c.decrypt_init(kp, res) do |eng|
      until encContIo.eof?
        s = encContIo.read(1024)
        eng.decrypt_update(s) do |ops, val|
          case ops
          when :plain
            dig.digest_update(val)
          end
        end
      end
    end
    digRes2 = dig.digest_final

    expect(digRes2 == digRes).to be true

  end

end
