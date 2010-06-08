
module Loquacious

  #
  #
  class Configuration

    # :stopdoc:
    class Error < StandardError; end
    @table = Hash.new
    # :startdoc:

    class << self
      # call-seq:
      #    Configuration.for( name )
      #    Configuration.for( name ) { block }
      #
      # Returns the configuration associated with the given _name_. If a
      # _block_ is given, then it will be used to create the configuration.
      #
      # The same _name_ can be used multiple times with different
      # configuration blocks. Each different block will be used to add to the
      # configuration; i.e. the configurations are additive.
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

      # call-seq:
      #    Configuration.help_for( name, opts = {} )
      #
      # Returns a Help instance for the configuration associated with the
      # given _name_. See the Help#initialize method for the options that
      # can be used with this method.
      #
      def help_for( name, opts = {} )
        ::Loquacious::Configuration::Help.new(name, opts)
      end
      alias :help :help_for
    end

    Keepers = %r/^__|^object_id$|^initialize$|^\w+\?$/
    instance_methods(true).each do |m|
      next if m[Keepers]
      undef_method m
    end
    Kernel.methods.each do |m|
      next if m[Keepers]
      module_eval <<-CODE
        def #{m}( *args, &block )
          self.method_missing('#{m}', *args, &block)
        end
      CODE
    end

    # Accessor for the description hash.
    attr_reader :__desc

    # Create a new configuration object and initialize it using an optional
    # _block_ of code.
    #
    def initialize( &block )
      @__desc = Hash.new
      self.merge!(DSL.evaluate(&block)) if block
    end

    # When invoked, an attribute reader and writer are defined for the
    # _method_. Any arguments given are used to set the value of the
    # attributes. If a _block_ is given, then the attribute is a nested
    # configuration and the _block_ is evaluated in the context of a new
    # configuration object.
    #
    def method_missing( method, *args, &block )
      m = method.to_s.delete('=').to_sym

      __eigenclass_eval "attr_writer :#{m}"
      __eigenclass_eval <<-CODE
        def #{m}( *args, &block )
          if args.empty? and !block
            return @#{m} if @#{m}.kind_of?(Configuration)
            return @#{m}.respond_to?(:call) ? @#{m}.call : @#{m}
          end

          v = (1 == args.length ? args.first : args)
          v = DSL.evaluate(&block) if block

          if @#{m}.kind_of?(Configuration)
            @#{m}.merge! v
          else
            @#{m} = v
          end

          return @#{m} if @#{m}.kind_of?(Configuration)
          return @#{m}.respond_to?(:call) ? @#{m}.call : @#{m}
        end
      CODE

      __desc[m] = nil

      default = (args.empty? and !block) ? Loquacious::Undefined.new(m.to_s) : nil
      self.__send("#{m}=", default)
      self.__send("#{m}", *args, &block)
    end

    # Only invoke public methods on the Configuration instances.
    #
    def __send( symbol, *args, &block )
      if self.respond_to? symbol
        self.__send__(symbol, *args, &block)
      else
        self.method_missing(symbol, *args, &block)
      end
    end

    # Evaluate the given _code_ string in the context of this object's
    # eigenclass (singleton class).
    #
    def __eigenclass_eval( code )
      ec = class << self; self; end
      ec.module_eval code
    rescue StandardError
      Kernel.raise Error, "cannot evalutate this code:\n#{code}\n"
    end

    # Merge the contents of the _other_ configuration into this one. Values
    # from the _other_ configuratin will overwite values in this
    # configuration.
    #
    # This function is recursive. Nested configurations will be merged with
    # their counterparts in the _other_ configuration.
    #
    def merge!( other )
      return self if other.equal? self
      Kernel.raise Error, "can only merge another Configuration" unless other.kind_of?(Configuration)

      other.__desc.each do |key,desc|
        value = other.__send(key)
        if self.__send(key).kind_of?(Configuration)
          self.__send(key).merge! value
        else
          self.__send("#{key}=", value)
        end
        __desc[key] = desc
      end

      self
    end

    # Provides hash accessor notation for configuration values.
    #
    #   config = Configuration.for('app') {
    #              port  1234
    #            }
    #   config[:port]  #=> 1234
    #   config.port    #=> 1234
    #
    def []( key )
      self.__send(key)
    end

    # Provides hash accessor notation for configuration values.
    #
    #   config = Configuration.for('app')
    #   config[:port] = 8808
    #   config.port            #=> 8808
    #
    def []=( key, value )
      self.__send(key, value)
    end


    # Implementation of a doman specific language for creating configuration
    # objects. Blocks of code are evaluted by the DSL which returns a new
    # configuration object.
    #
    class DSL
      instance_methods(true).each do |m|
        next if m[Keepers]
        undef_method m
      end
      private_instance_methods(true).each do |m|
        next if m[Keepers]
        undef_method m
      end
      Kernel.methods.each do |m|
        next if m[Keepers]
        module_eval <<-CODE
          def #{m}( *args, &block )
            self.method_missing('#{m}', *args, &block)
          end
        CODE
      end

      # Create a new DSL and evaluate the given _block_ in the context of
      # the DSL. Returns a newly created configuration object.
      #
      def self.evaluate( &block )
        dsl = self.new(&block)
        dsl.__config
      end

      # Returns the configuration object.
      attr_reader :__config

      # Creates a new DSL and evaluates the given _block_ in the context of
      # the DSL.
      #
      def initialize( &block )
        @description = nil
        @__config = Configuration.new
        Object.instance_method(:instance_eval).bind(self).
            call(&block) if block
      end

      # Dynamically adds the given _method_ to the configuration as an
      # attribute. The _args_ will be used to set the value of the
      # attribute. If a _block_ is given then the _args_ are ignored and the
      # attribute will be a nested configuration object.
      #
      def method_missing( method, *args, &block )
        m = method.to_s.delete('=').to_sym

        if args.length > 1
          opts = args.last.instance_of?(Hash) ? args.pop : {}
          self.desc(opts[:desc]) if opts.has_key? :desc
        end

        __config.__send(m, *args, &block)
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
        string.gutter!
        @description = string.empty? ? nil : string
      end
    end  # class DSL

  end  # class Configuration
end  # module Loquacious

