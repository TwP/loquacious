
module Loquacious

  #
  #
  class Configuration

    # :stopdoc:
    class Error < StandardError; end
    @table = Hash.new
    # :startdoc:

    class << self

      #
      #
      def for( name, &block )
        if block.nil?
          return @table.has_key?(name) ? @table[name] : nil
        end

        cfg = DSL.evaluate(&block)

        if @table.has_key? name
          @table[name].merge! cfg
        else
          @table[name] = cfg
        end
      end
    end  # class << self

    exceptions = %w{object_id instance_of? kind_of? equal?}
    exceptions.map! {|s| s.to_sym} if RUBY_1_9
    instance_methods.each do |m|
      undef_method m unless m[%r/^__/] or exceptions.include? m
    end

    #
    #
    def initialize( &block )
      self.merge!(DSL.evaluate(&block)) if block
    end

    #
    #
    def method_missing( method, *args, &block )
      m = method.to_s.delete('=').to_sym

      __eigenclass_eval "attr_writer :#{m}"
      __eigenclass_eval <<-CODE
        def #{m}( *args, &block )
          v = (1 == args.length ? args.first : args)
          v = nil if args.empty?
          v = DSL.evaluate(&block) if block
          
          return @#{m} unless v

          if @#{m}.kind_of?(Configuration)
            @#{m}.merge! v
          else
            @#{m} = v
          end
          return @#{m}
        end
      CODE

      __desc[m]
      self.__send__("#{m}=", nil)
      self.__send__("#{m}", *args, &block)
    end

    #
    #
    def __eigenclass_eval( code )
      ec = class << self; self; end
      ec.module_eval code
    rescue StandardError
      raise Error, "cannot evalutate this code:\n#{code}\n"
    end

    #
    #
    def __desc
      @__desc ||= Hash.new
    end

    #
    #
    def []( sym )
      __desc.has_key?(sym) ? __desc[sym] : nil
    end

    #
    #
    def merge!( other )
      return self if other.equal? self
      raise Error, "can only merge another Configuration" unless other.kind_of?(Configuration)

      other.__desc.each do |key,desc|
        value = other.__send__(key)
        if self.__send__(key).kind_of?(Configuration)
          self.__send__(key).merge! value
        else
          self.__send__("#{key}=", value)
        end
        __desc[key] = desc
      end

      self
    end

    # Implementation of a doman specific language for creating configuration
    # objects. Blocks of code are evaluted by the DSL which returns a new
    # configuration object.
    #
    class DSL
      alias :__instance_eval :instance_eval

      instance_methods.each do |m|
        undef_method m unless m[%r/^(__|object_id)/]
      end 

      # Create a new DSL and evaluate the given _block_ in the context of
      # the DSL. Returns a newly created configuration object.
      #
      def self.evaluate( &block )
        dsl = self.new(&block)
        dsl.__config
      end

      # Creates a new DSL and evaluates the given _block_ in the context of
      # the DSL.
      #
      def initialize( &block )
        @description = nil
        self.__instance_eval(&block) if block
      end

      # Dynamically adds the given _method_ to the configuration as an
      # attribute. The _args_ will be used to set the value of the
      # attribute. If a _block_ is given then the _args_ are ignored and the
      # attribute will be a nested configuration object.
      #
      def method_missing( method, *args, &block )
        m = method.to_s.delete('=').to_sym

        opts = Hash === args.last ? args.pop : {}
        self.desc(opts[:desc]) if opts.has_key?(:desc)

        __config.__send__(m, *args, &block)
        __config.__desc[m] = @description

        @description = nil
      end

      # Store the _string_ as the description for the next attribute that
      # will be configured. This description will be overwritten if the
      # attribute has a description passed as an options hash.
      #
      def desc( string )
        string = string.to_s
        string.strip!
        string.gsub! %r/^[\t\f\r ]*\|?/, ''
        @description = string.empty? ? nil : string
      end
      alias :_ :desc

      # Returns the configuration object.
      #
      def __config
        @__config ||= Configuration.new
      end

    end  # class DSL

  end  # class Configuration
end  # module Loquacious

# EOF
