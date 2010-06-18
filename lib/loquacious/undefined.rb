
module Loquacious

  # Represents an undefined configuration value. An undefined value is
  # assigned to each configuration propery by default. Any method can be
  # invoked on an undefined value, and a warning message will be printed to
  # the IO stream (defaulting to $stderr).
  #
  # The purpose of this class is to provide the user with a helpful message
  # that the configuration values they are trying to use have not been setup
  # correctly.
  #
  class Undefined

    Keepers = %r/^__|^object_id$|^initialize$|^call$|^\w+\?$/
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
    undef_method :method_missing

    @io = $stderr
    @first_time = true

    class << self
      attr_accessor :io

      # Write a warning message to the Undefined class IO stream. By default,
      # this IO stream is set to the Ruby $stderr output.
      #
      def warn( key )
        if @first_time
          @io.puts <<-__
---------------------------------------------------------------------------
The Loquacious configuration system has detected that one or moe
settings have an undefined value. An attempt is being made to reference
sub-properties of these undefined settings. Messages will follow containing
information about the undefined properties.
---------------------------------------------------------------------------
          __
          @first_time = false
        end

        @io.puts "Access to undefined value #{key.first.inspect}: #{key.join('.')}"
      end
    end

    # Creates a new undefined value returned from the lookup _key_ in some
    # configuration object. The _key_ is used to alert the user where the
    # undefined value came from.
    #
    def initialize( key )
      @key = Kernel.Array(key)
    end

    # An undefined value acts like a +nil+ in that it has no value of its own.
    # This method always returns +true+.
    #
    def nil?() true; end

    # We can respond to any method except :call. The call method is reserved
    # for Procs and lambdas, and it is used internally by loquacious for lazy
    # evaluation of configuration parameters.
    #
    def respond_to_missing?( id, priv = false ) id != :call; end

    # For every method invoked on an undefined object, generate a warning
    # message describing the undefined value and the method that was called.
    #
    # Returns a new undefined object with the most recent method included in
    # the key name.
    #
    def method_missing( method, *args, &block )
      key = @key.dup << method.to_s
      Undefined.warn key
      return Undefined.new(key)
    end

  end  # class Undefined
end  # module Loquacious

