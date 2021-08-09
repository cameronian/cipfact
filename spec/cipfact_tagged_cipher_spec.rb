# frozen_string_literal: true

require 'stringio'
require 'cipfact/ruby'

RSpec.describe "Cipfact Tagged" do

  it 'encrypt & decrypt to multiple recipients splited output' do
    cf = Cipfact.instance(:ruby)
    recp1 = cf.genkey(:rsa)
    recp2 = cf.genkey(:ecc)
    recp3 = cf.genkey(:aes) 

    c = cf.cipher(:tagged)
    data = "testing for multiple recipients"
    header = StringIO.new
    cipher = StringIO.new
    c.encrypt_init 
    c.split_output(header, cipher)
    c.add_recipient recp1

    c.encrypt_update(data)
    c.encrypt_final

    head = header.string
    expect(head).not_to be_nil
    enc = cipher.string
    expect(enc).not_to be_nil

    decOut = StringIO.new
    c.splited_content(StringIO.new(enc))
    c.decrypt_output(decOut)

    c.decrypt_init(head, recp1)
    # for splited content, this method is not called
    #c.decrypt_update(enc)
    c.decrypt_final
    expect(decOut.string == data).to be true

  end

  it 'encrypt to multiple recipients combined output' do
    cf = Cipfact.instance(:ruby)
    recp1 = cf.genkey(:rsa)
    recp2 = cf.genkey(:ecc)
    recp3 = cf.genkey(:aes) 

    c = cf.cipher(:tagged)
    data = "testing for multiple recipients"

    output = StringIO.new
    c.encrypt_init 
    c.combined_output(output)
    c.add_recipient recp1

    c.encrypt_update(data)
    c.encrypt_final

    out = output.string
    expect(out).not_to be_nil


    #c.decrypt_init(recp1, head)
    #c.
    #c.decrypt_update(enc)
    #c.decrypt_final

  end


end
