
require 'singleton'

require 'toolrack'
require 'tlogger'

require_relative "tag"

module Cipfact
 
  # Error belongs to the Spec DSL 
  class SpecDslError < StandardError; end
 
  # Singleton for the Spec DSL engine
  class SpecDslConfig
    include Singleton
    attr_accessor :tspec_root, :logger
    def initialize
      @tspec_root = File.expand_path(File.join(File.dirname(__FILE__),"..","..","tspec"))
      @logger = Tlogger.new
    end
  end 

  # 
  # Spec Domain Specific Language (DSL) core
  # This DSL is meant to provide 
  #
  # * Standardize binary layout of particular object
  # * Assist in documentation of the binary layout in single place
  #
  module SpecDsl
    include ToolRack::ConditionUtils

    attr_reader :id
    def initialize
      @field_seq = []
      @logger = SpecDslConfig.instance.logger
      @fields = { }
      @ofields = { }
    end

    ### 
    # DSL keyword spec. Entry point of the DSL processing
    # @param [Symbol] id Identity that can be reference later
    ###
    def spec(id, &block)
      @id = id
      self.instance_eval(&block)  
    end # spec DSL

    # DSL keyword field. Mandatory fields of this structure.
    # @param [Symbol] id Key of this field. Value later shall be bind to this key via {#set}
    # @param [Symbol] ftype Type of this value for ASN.1 encoding
    # @param [Symbol] defVal Default value of this key
    # @param [Hash] opts Additional options for the field. 
    def field(id, ftype, defVal = "", opts = { }, &block)
      create_field(id, ftype, defVal, opts, &block)
    end # field DSL

    # DSL keyword field_opts. Optional field of this structure.
    # @param [Symbol] id Key of this optional field. Value later shall be bind to this key via {#set}
    # @param [Symbol] ftype Type of this value for ASN.1 encoding
    # @param [Symbol] defVal Default value of this key
    # @param [Hash] opts Additional options for the optional field. 
    def field_opts(id, ftype, defVal = "", opts = { }, &block)
      create_optional_field(id, ftype, defVal, opts, &block)
    end
    alias_method :ofield, :field_opts

    # DSL keyword tfield.
    # Means the field is from another tspec
    # @param [Symbol] id Key of this field. Value later shall be bind to this key via {#set}
    # @param [String] tspec_name The TSpec name to load the spec
    def tfield(id, ftype, tspec_name, version = "1.0", opts = { }, &block)
      inst = SpecDslBuilder.load_tspec(tspec_name, version)
      @logger.debug "Created tfield '#{tspec_name}' version '#{version}'"
      create_field(id, ftype, inst, opts, &block) 
    end
    ###
    # end DSL
    ###

    # 
    # Method to merge all extracted fields into single hash
    # @return [Hash] Hash of all mandatory's and optional's field key & value
    # to be processed by other area of the program
    #
    def field_map
      map = { }
      map.merge!(@fields) if not_empty?(@fields)
      map.merge!(@ofields) if not_empty?(@ofields)
      map.each { |k,v| map[k] = v[:value] }
      map
    end

    # 
    # Bind a value to the field as defined in the tspec file
    # @param [Symbol] field Field ID that needs to be bind
    # @param [Any] value to be bind to given field ID
    def set(field, value)
      if @fields.keys.include?(field)
        @fields[field][:value] = value
      elsif @ofields.keys.include?(field)
        @ofields[field][:value] = value
      else
        raise Cipfact::SpecDslError, "Field '#{field}' is not defined inside the spec"
      end
    end # set

    def set_t(field, tfield, value)
      if @fields.keys.include?(field)
        if not_empty?(@fields[field])
          if @fields[field].is_a?(TSpec)
            @field[field].set(tfield, value)
          else
            raise Cipfact::SpecDslError, "Field '#{field}' is not an expected TSpec object. Please use set() for non tspec field"
          end
        else
          raise Cipfact::SpecDslError, "Field '#{field}' is not defined inside the spec"
        end
      elsif @ofields.keys.include?(field)
        if not_empty?(@ofields[field])
          if @ofields[field].is_a?(TSpec)
            @ofield[field].set(tfield, value)
          else
            raise Cipfact::SpecDslError, "Optional field '#{field}' is not an expected TSpec object. Please use set() for non tspec field"
          end
        else
          raise Cipfact::SpecDslError, "Optional field '#{field}' is not defined inside the spec"
        end
      else
        raise Cipfact::SpecDslError, "Field '#{field}' is not defined inside the spec"
      end
    end

    # 
    # Return value bound to the given field
    # @param [Symbol] field Field ID being queried
    # @return [Any] value bounded to the field ID
    #
    def value(field)
      val = nil
      val = @fields[field][:value]  if not_empty?(@fields) and @fields.keys.include?(field)
      val = @ofields[field][:value] if is_empty?(val) and not_empty?(@ofields) and @ofields.keys.include?(field)
      val
    end # value

    def required_fields
      @fields.keys 
    end

    def required_but_still_empty_fields
      res = []
      @fields.each do |k,v|
        res << k if is_empty?(v[:value])
      end
      res.sort
    end

    def optional_fields
      @ofields.keys
    end

    def is_completed?
      not (required_but_still_empty_fields.length > 0)
    end

    # 
    # Return the structure in ASN.1 in binary structure (byte array)
    #
    def to_bin(opts = { }, &block)
      raise Cipfact::SpecDslError, "Block is required" if not block
      seq = to_object(opts, &block)
      block.call(:to_bin, seq)
    end # to_bin

    def to_object(opts = { }, &block)
      raise Cipfact::SpecDslError, "Block is required" if not block
      ar = to_array(&block)
      block.call(:encode, :seq, ar)
    end

    # 
    # Return the structore in ASN.1 object array. 
    # This array allow external applications to modified it if required for the buisness purposes 
    # before the array is converted into binary
    #
    def to_array(opts = { }, &block)

      raise Cipfact::SpecDslError, "Block is required" if not block
      raise Cipfact::SpecDslError, "Spec is not completed! The following keys are still vacant : [#{required_but_still_empty_fields.join(", ")}]" if not is_completed?

      res = []
      @field_seq.each do |f|
        val = nil
        if @fields.keys.include?(f)
          val = @fields[f]

          raise Cipfact::SpecDslError, "Mandatory field '#{f}' cannot be empty" if is_empty?(val)

          if val.is_a?(Tspec)
            res.concat(val.to_array)
          else
            #@logger.debug "#{f} / #{val[:ftype]} / #{val[:value]}"
            res << block.call(:encode,val[:ftype], val[:value])
          end

        elsif @ofields.keys.include?(f)
          val = @ofields[f]

          if val.is_a?(Tspec)
            res.concat(val.to_array)
          else
            if not_empty?(val[:value])
              #@logger.debug "#{f} (Optional) / #{val[:ftype]} / #{val[:value]}"
              res << block.call(:encode,val[:ftype], val[:value])
            end
          end

        else
          raise Cipfact::SpecDslError, "Field '#{f}' is not defined everywhere!"
        end

      end

      res

    end # to_array

    # 
    # Load the tspec structure and its corresponding tagged value in each fields of the tspec structure
    #
    def load_from_array(asn1, &block)
      raise Cipfact::SpecDslError, "Block is required" if not block
      if not_empty?(asn1)
        cnt = 0
        @field_seq.each do |f|
          set(f, block.call(:value, asn1[cnt])) #TagProvider.value(asn1[cnt]))
          cnt += 1
        end
        self
      else
        raise Cipfact::SpecDslError, "ASN.1 is empty"
      end 
    end

    private
    def create_field(id, ftype, defVal = "", opts = { }, &block)
      if is_empty?(@fields)
        @fields = { }
      end

      raise Cipfact::SpecDslError, "Given id '#{id}' already defined" if @fields.keys.include?(id)

      @fields[id] = { ftype: ftype }
      @fields[id][:value] = defVal if not_empty?(defVal)
      @fields[id][:opts] = opts if not_empty?(opts)

      @field_seq << id

      @fields
    end # create_field

    def create_optional_field(id, ftype, defVal = "", opts = { }, &block)
      if is_empty?(@ofields)
        @ofields = { }
      end

      raise Cipfact::SpecDslError, "Given id '#{id}' already defined" if @ofields.keys.include?(id)

      @ofields[id] = { ftype: ftype }
      @ofields[id][:value] = defVal if not_empty?(defVal)
      @ofields[id][:opts] = opts if not_empty?(opts)

      @field_seq << id

      @ofields
    end # create_optional_field

  end # module SpecDsl

  # 
  # Concrete class implementing the DSL processing
  # 
  class Tspec
    include SpecDsl
    def initialize(path, opts = { })
      super()
      if File.exist?(path)
        self.instance_eval(File.read(path))
      else
        raise Cipfact::SpecDslError, "Given Tspec '#{path}' not found"
      end
    end # initialize
 
    def is_equals?(field, val)
      if @fields.keys.include?(field)
        @fields[field][:value] == val
      elsif @ofields.keys.include?(field)
        @ofields[field][:value] == val
      end 
    end
    alias :is_equal? :is_equals?
    alias :equal? :is_equals?
    alias :equals? :is_equals?

  end # class Tspec

  class SpecDslBuilder
    extend Antrapol::ToolRack::ConditionUtils

    def self.instance(val, version = "1.0",&block)
      load_tspec(val,version)
    end # self.instance

    def self.from_array(asn1, opts = { }, &block)
      
      raise Cipfact::SpecDslError, "Block is required" if not block

      if not_empty?(asn1)
        val = block.call(:value, asn1[0]) #TagProvider.value(asn1[0])
        const = Tag.constant(val)
       
        if not_empty?(opts[:verify_tspec])
          raise Cipfact::SpecDslError, "Expected '#{opts[:verify_tspec]}' but loaded '#{const}'" if opts[:verify_tspec] != const
        end

        ver = block.call(:value, asn1[1]) #TagProvider.value(asn1[1])
        if not_empty?(const)
          tspec = load_tspec(const, version_int_to_string(ver))
          # complete the whole ASN.1 structure with keys and values pair as in the given binary
          tspec.load_from_array(asn1, &block)
        else
          raise Cipfact::SpecDslError, "Cannot get constant from value '#{val}'"
        end
      else
        raise Cipfact::SpecDslError, "Given data to load from ASN.1 is empty"
      end 

    end # from_array

    def self.from_bin(bin, opts = { }, &block)
      
      raise Cipfact::SpecDslError, "Block is required" if not block

      if not_empty?(bin)
        dec = block.call(:decode, bin, opts) #TagProvider.decode(bin, opts)
        #from_array(dec.first, opts.merge( { asn1BinLen: dec[1] }), &block)
        from_array(dec, opts, &block)
      else
        raise Cipfact::SpecDslError, "Given binary to load into ASN.1 is empty"
      end 

    end # from_bin

    def self.version_int_to_string(verInt)
      case verInt
      when 0x0100
        "1.0"
      else
        raise Cipfact::SpecDslError, "Unknown version integer '#{verInt}'"
      end
    end

    def self.version_string_to_int(verStr)
      case verStr
      when "1.0"
        0x0100
      else
        raise Cipfact::SpecDslError, "Unknown version string '#{verStr}'"
      end
    end

    private
    def self.load_tspec(val,version = "1.0")

      specPath = File.join(SpecDslConfig.instance.tspec_root,version,"#{val}.tspec")
      if File.exist?(specPath)
        Tspec.new(specPath)
      else
        raise Cipfact::SpecDslError, "Tspec '#{specPath}' not found"
      end

    end # load_tspec

  end # class SpecDslBuilder

end # Cipfact


if $0 == __FILE__
  inst = Cipfact::SpecDslBuilder.instance(:kdf_scrypt_envp)
  p inst
  p inst.required_fields
  p inst.required_but_still_empty_fields

  require 'gcrypto'
  require 'gcrypto_jce'

  cc = Gcrypto::CryptoContext.instance(:aes)
  cc.random_iv

  p inst.is_completed?
  inst.set(:block_size,1024)
  inst.set(:cost_param, 1024)
  inst.set(:output_in_bits, 1024)
  inst.set(:parallel, 1)
  inst.set(:salt, cc.iv)

  p inst.to_asn1

end
