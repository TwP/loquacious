
module Loquacious

  # :stopdoc:
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  class << self

    # Returns the configuration associated with the given _name_. If a
    # _block_ is given, then it will be used to create the configuration.
    #
    # The same _name_ can be used multiple times with different
    # configuration blocks. Each different block will be used to add to the
    # configuration; i.e. the configurations are additive.
    #
    def configuration_for( name, &block )
      ::Loquacious::Configuration.for(name, &block)
    end
    alias :configuration :configuration_for
    alias :config_for    :configuration_for
    alias :config        :configuration_for

    # Returns a Help instance for the configuration associated with the
    # given _name_. See the Help#initialize method for the options that
    # can be used with this method.
    #
    def help_for( name, opts = {} )
      ::Loquacious::Configuration.help_for(name, opts)
    end
    alias :help :help_for

    # Returns the version string for the library.
    #
    def version
      @version ||= File.read(path('version.txt')).strip
    end

    # Returns the library path for the module. If any arguments are given,
    # they will be joined to the end of the libray path using
    # <tt>File.join</tt>.
    #
    def libpath( *args, &block )
      rv =  args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
      if block
        begin
          $LOAD_PATH.unshift LIBPATH
          rv = block.call
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

    # Returns the lpath for the module. If any arguments are given, they
    # will be joined to the end of the path using <tt>File.join</tt>.
    #
    def path( *args, &block )
      rv = args.empty? ? PATH : ::File.join(PATH, args.flatten)
      if block
        begin
          $LOAD_PATH.unshift PATH
          rv = block.call
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

    # This is merely a convenience method to remove methods from the
    # Loquacious::Configuration class. Some ruby gems add lots of crap to the
    # Kernel module, and this interferes with the configuration system. The
    # remove method should be used to anihilate unwanted methods from the
    # configuration class as needed.
    #
    #   Loquacious.remove :gem           # courtesy of rubygems
    #   Loquacious.remove :test, :file   # courtesy of rake
    #   Loquacious.remove :main          # courtesy of main
    #
    def remove( *args )
      args.each { |name|
        name = name.to_s.delete('=')
        code = <<-__
          undef_method :#{name} rescue nil
          undef_method :#{name}= rescue nil
        __
        Loquacious::Configuration.module_eval code
        Loquacious::Configuration::DSL.module_eval code
      }
    end

    # A helper method that will create a deep copy of a given Configuration
    # object. This method accepts either a Configuration instance or a name
    # that can be used to lookup the Configuration instance (via the
    # "Loquacious.configuration_for" method).
    #
    #   Loquacious.copy(config)
    #   Loquacious.copy('name')
    #
    # Optionally a block can be given. It will be used to modify the returned
    # copy with the given values. The Configuration object being copied is
    # never modified by this method.
    #
    #   Loquacious.copy(config) {
    #     foo 'bar'
    #     baz 'buz'
    #   }
    #
    def copy( config, &block )
      config = Configuration.for(config) unless config.instance_of? Configuration
      return unless config

      rv = Configuration.new
      rv.merge!(config)

      # deep copy
      rv.__desc.each do |key,desc|
        value = rv.__send(key)
        next unless value.instance_of? Configuration
        rv.__send("#{key}=", ::Loquacious.copy(value))
      end

      rv.merge!(Configuration::DSL.evaluate(&block)) if block
      rv
    end

  end  # class << self
end  # module Loquacious

Loquacious.libpath {
  require 'loquacious/core_ext/string'
  require 'loquacious/undefined'
  require 'loquacious/configuration'
  require 'loquacious/configuration/iterator'
  require 'loquacious/configuration/help'
}

