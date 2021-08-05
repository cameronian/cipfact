# frozen_string_literal: true

require 'cipfact/ruby'

RSpec.describe "Cipfact Digest" do

  it 'generates digest from given data' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    d = cf.digest_eng(:sha256)
    expect(d).not_to be_nil

    res = d.digest("whatever this content is")
    expect(res).not_to be_nil

    res2 = d.digest("whatever this content is")
    expect(res == res2).to be true

    res3 = d.digest(InputFile.new("spec/cipfact_ecc_spec.rb"))
    expect(res3).not_to be_nil
 
    res4 = d.digest(InputFile.new("spec/cipfact_ecc_spec.rb"))
    expect(res4 == res3).to be true

  end

  it 'generates digest from given data with block' do

    cf = Cipfact.instance(:ruby)
    expect(cf).not_to be_nil

    d = cf.digest_eng(:sha256) 
    expect(d).not_to be_nil

    data = "whatever this content is"
    bres = d.digest_init do |dig|
      dig.digest_update data
    end

    res = d.digest(data)
    expect(res).not_to be_nil
    expect(bres == res).to be true

    res2 = d.digest(data)
    expect(res == res2).to be true

    res3 = d.digest(InputFile.new("spec/cipfact_ecc_spec.rb"))
    expect(res3).not_to be_nil
 
    res4 = d.digest(InputFile.new("spec/cipfact_ecc_spec.rb"))
    expect(res4 == res3).to be true

    bres2 = d.digest_init do |eng|
      File.open("spec/cipfact_ecc_spec.rb","rb") do |f|
        eng.digest_update f.read
      end
    end
    expect(bres2).not_to be_nil
    expect(bres2 == res4).to be true

    d.digest_init
    d.digest_update(data)
    bres3 = d.digest_final
    expect(bres3 == bres).to be true

  end


end
