
module Loquacious

  # :stopdoc:
  VERSION = '1.1.1'
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
      VERSION
    end

    # Returns the library path for the module. If any arguments are given,
    # they will be joined to the end of the libray path using
    # <tt>File.join</tt>.
    #
    def libpath( *args )
      args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
    end

    # Returns the lpath for the module. If any arguments are given, they
    # will be joined to the end of the path using <tt>File.join</tt>.
    #
    def path( *args )
      args.empty? ? PATH : ::File.join(PATH, args.flatten)
    end

    # Utility method used to require all files ending in .rb that lie in the
    # directory below this file that has the same name as the filename
    # passed in. Optionally, a specific _directory_ name can be passed in
    # such that the _filename_ does not have to be equivalent to the
    # directory.
    #
    def require_all_libs_relative_to( fname, dir = nil )
      dir ||= ::File.basename(fname, '.*')
      search_me = ::File.expand_path(
          ::File.join(::File.dirname(fname), dir, '**', '*.rb'))

      Dir.glob(search_me).sort.each {|rb| require rb}
    end

  end  # class << self
end  # module Loquacious

Loquacious.require_all_libs_relative_to(__FILE__)

# EOF
