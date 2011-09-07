
module Loquacious

  # A Configuration provides a "blank slate" for storing configuration
  # properties along with descriptions and default values. Configurations are
  # accessed by name, and hence, the configuration properties can be retrieved
  # from any location in your code.
  #
  # Each property has an associated description that can be displayed to the
  # user via the Configuration::Help class. This is the main point of the
  # Loquacious library - tell the user what all yoru configruation properties
  # actually do!
  #
  # Each configurationp property can also have a default value that is
  # returned if no value has been set for that property. Each property should
  # hae a sensible default - the user should not have to configure every
  # property in order to use a piece of code.
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

        if @table.has_key? name
          DSL.evaluate(:config => @table[name], &block)
        else
          @table[name] = DSL.evaluate(&block)
        end
      end

      # call-seq:
      #    Configuration.defaults_for( name ) { block }
      #
      # Set the default values for the configuration associated with the given
      # _name_. A _block_ is required by this method.
      #
      # Default values do not interfere with normal configuration values. If
      # both are defined for a particualr configruation setting, then the
      # regular configuration value will be returned.
      #
      # Defaults allow the user to define configuration values before the
      # library defaults have been loaded. They prevent library defaults from
      # overriding user settings.
      #
      def defaults_for( name, &block )
        raise "defaults require a block" if block.nil?

        if @table.has_key? name
          DSL.evaluate(:config => @table[name], :defaults_mode => true, &block)
        else
          @table[name] = DSL.evaluate(:defaults_mode => true, &block)
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

      # call-seq:
      #   Configuration.to_hash( config )
      #
      # Recursively convert a configuration object to a hash. This is useful for
      # passing the configuration to a method which only accepts an option hash.
      #
      def to_hash( config )
        hash = {}
        Iterator.new(config).each do |node|
          value = node.obj
          hash[node.name] = node.config? ? to_hash(value) : value
        end
        hash
      end
    end

    instance_methods(true).each do |m|
      next if m[::Loquacious::KEEPERS]
      undef_method m
    end
    Kernel.methods.each do |m|
      next if m[::Loquacious::KEEPERS]
      module_eval <<-CODE
        def #{m}( *args, &block )
          self.method_missing('#{m}', *args, &block)
        end
      CODE
    end
    undef_method :method_missing rescue nil

    # Accessor for the description hash.
    attr_reader :__desc

    # Accessor for configuration values
    attr_reader :__values

    # Accessor for configuration defaults
    attr_reader :__defaults

    # Flag to switch the configuration object into defaults mode. This allows
    # default values to be set instead regular values.
    attr_accessor :__defaults_mode

    # Create a new configuration object and initialize it using an optional
    # _block_ of code.
    #
    def initialize( &block )
      @__desc = Hash.new
      @__values = Hash.new
      @__defaults = Hash.new
      @__defaults_mode = false
      DSL.evaluate(:config => self, &block) if block
    end

    # When invoked, an attribute reader and writer are defined for the
    # _method_. Any arguments given are used to set the value of the
    # attributes. If a _block_ is given, then the attribute is a nested
    # configuration and the _block_ is evaluated in the context of a new
    # configuration object.
    #
    def method_missing( method, *args, &block )
      m = method.to_s.delete('=').to_sym

      __eigenclass_eval "def #{m}=( value ) @__values[#{m.inspect}] = value; end", __FILE__, __LINE__
      __eigenclass_eval <<-CODE, __FILE__, __LINE__+1
        def #{m}( *args, &block )
          value = @__values[#{m.inspect}]

          if args.empty? and !block
            return value if value.kind_of?(Configuration)
            value = @__defaults[#{m.inspect}] if value.kind_of?(Loquacious::Undefined) and @__defaults.has_key? #{m.inspect}
            return value.respond_to?(:call) ? value.call : value
          end

          if block
            v = DSL.evaluate(:defaults_mode => __defaults_mode, &block)
            if value.kind_of?(Configuration)
              value.merge! v
            else
              @__values[#{m.inspect}] = v
            end
          else
            v = (1 == args.length ? args.first : args)
            if __defaults_mode
              @__defaults[#{m.inspect}] = v
            else
              @__values[#{m.inspect}] = v
            end
          end
        end
      CODE

      __desc[m] = nil unless __desc.has_key? m

      default = ((__defaults_mode or args.empty?) and !block) ? Loquacious::Undefined.new(m.to_s) : nil
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
    def __eigenclass_eval( code, file, line )
      ec = class << self; self; end
      ec.module_eval code, file, line
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

      other_values = other.__values
      other_defaults = other.__defaults

      other.__desc.each do |key,desc|
        value = @__values[key]
        other_value = other_values[key]

        if value.kind_of?(Configuration) and other_value.kind_of?(Configuration)
          value.merge! other_value
        elsif !other_value.kind_of?(Loquacious::Undefined)
          @__values[key] = other_value
        end

        if other_defaults.has_key? key
          @__defaults[key] = other_defaults[key]
        end

        if desc
          __desc[key] = desc
        end
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

    # Recursively convert the configuration object to a hash. This is useful for
    # passing the configuration to a method which only accepts an option hash.
    #
    def to_hash
      self.class.to_hash(self)
    end

    # Implementation of a domain specific language for creating configuration
    # objects. Blocks of code are evaluted by the DSL which returns a new
    # configuration object.
    #
    class DSL
      instance_methods(true).each do |m|
        next if m[::Loquacious::KEEPERS]
        undef_method m
      end
      private_instance_methods(true).each do |m|
        next if m[::Loquacious::KEEPERS]
        undef_method m
      end
      Kernel.methods.each do |m|
        next if m[::Loquacious::KEEPERS]
        module_eval <<-CODE, __FILE__, __LINE__+1
          def #{m}( *args, &block )
            self.method_missing('#{m}', *args, &block)
          end
        CODE
      end
      undef_method :method_missing rescue nil

      # Create a new DSL and evaluate the given _block_ in the context of
      # the DSL. Returns a newly created configuration object.
      #
      def self.evaluate( opts = {}, &block )
        dsl = self.new(opts, &block)
        dsl.__config
      end

      # Returns the configuration object.
      attr_reader :__config

      # Creates a new DSL and evaluates the given _block_ in the context of
      # the DSL.
      #
      def initialize( opts = {}, &block )
        @description = nil
        @__config = opts[:config] || Configuration.new
        @__config.__defaults_mode = opts.key?(:defaults_mode) ? opts[:defaults_mode] : false
        instance_eval(&block)
      ensure
        @__config.__defaults_mode = false
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

        rv = __config.__send(m, *args, &block)
        __config.__desc[m] = @description if @description
        @description = nil
        rv
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

