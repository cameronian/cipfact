

module Cipfact
  module Wrapper

    attr_reader :delegate
    def initialize(obj)
      @delegate = obj
    end

    def ==(*args,&block)
      @delegate.send(:==, *args, &block)
    end

    def method_missing(mtd, *args, &block)
      @delegate.send(mtd, *args, &block) if not @delegate.nil?
    end
    
  end
end
