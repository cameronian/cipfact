# frozen_string_literal: true

require 'cipfact/ruby'

RSpec.describe "Cipfact KDF Scrypt" do

  it 'generates Scrypt hash from given password' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    kdf = cf.kdf_eng_instance(:kdf_scrypt)
    res, asn1 = kdf.derive("testing")

    res2, asn1 = kdf.derive("testing", asn1)
    expect(res == res2).to be true

    res3, asn1 = kdf.derive_init(asn1) do |eng|
      eng.derive_update("testing")
    end
    expect(res2 == res3).to be true

    kdf.derive_init(asn1)
    kdf.derive_update("testing")
    res4,asn1 = kdf.derive_final
    expect(res4 == res).to be true

  end

  it 'generates Scrypt hash from given long input' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    kdf = cf.kdf_eng_instance(:kdf_scrypt, :sha256)

    res, asn1 = kdf.derive_init do |eng|
      File.open('../../../Luna-SSL-Testing.7z',"rb") do |f|
        eng.derive_update f.read
      end
    end

    kdf2 = cf.kdf_eng_instance(:kdf_scrypt)
    res_, asn1_ = kdf2.derive_init do |eng|
      File.open('../../../Luna-SSL-Testing.7z',"rb") do |f|
        eng.derive_update f.read
      end
    end
    expect(res_ != res).to be true


    res2, asn12 = kdf.derive_init(asn1) do |eng|
      File.open('../../../Luna-SSL-Testing.7z',"rb") do |f|
        eng.derive_update f.read
      end
    end
    expect(res == res2).to be true

    kdf.derive_init(asn12)
    File.open('../../../Luna-SSL-Testing.7z',"rb") do |f|
      kdf.derive_update f.read
    end
    res4, asn14 = kdf.derive_final
    expect(res4 == res).to be true

  end


end
