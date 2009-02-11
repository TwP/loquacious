
module Loquacious

  class Iterator

    # :stopdoc:
    attr_reader :stack
    private :stack
    # :startdoc:

    # Create a new iterator that will operate on the _config_ (configuration
    # objet). The iterator allows the attributes of the configuration object
    # to be accessed -- this includes nested configuration objects.
    #
    def initialize( config )
      @config = config
      @stack = []
      reset
    end

    # Iterate over each node in the configuration object yielding each to
    # the supplied block in turn. The return value of the block is returned
    # from this method. +nil+ is returned if there are no nodes in the
    # iterator.
    #
    def each
      reset
      rv = nil

      while (node = next_node) do
        rv = yield node
      end
      return rv
    end

    # Find the given named _attribute_ in the iterator. Returns a node
    # representing the attribute; or +nil+ is returned if the named
    # attribute could not be found.
    #
    def find( attribute )
      attribute = attribute.to_s
      return if attribute.empty?

      node = self.each {|n| break n if n.name == attribute}
      reset
      return node
    end

  private

    # Reset the iterator back to the beginning.
    #
    def reset
      stack.clear
      stack << new_frame(@config)
    end

    # Returns the next node from the current iteration stack frame. Returns
    # +nil+ if there are no more nodes in the iterator.
    #
    def next_node
      frame = stack.last
      node = new_node(frame)

      while node.nil?
        stack.pop
        return if stack.empty?
        frame = stack.last
        node = new_node(frame)
      end

      frame.index += 1
      stack << new_frame(node.obj, node.name) if node.config?

      return node
    end

    # Create a new stack frame from the given _cfg_ (configuration object)
    # and the optional _prefix_. The _prefix_ is used to complete the full
    # name for each attribute key in the configuration object.
    #
    def new_frame( cfg, prefix = nil )
      keys = cfg.__desc.keys.map {|k| k.to_s}
      keys.sort!
      keys.map! {|k| k.to_sym}

      Frame.new(cfg, prefix.to_s, keys, 0)
    end

    # Create the next iteration node from the given stack _frame_. Returns
    # +nil+ when there are no more nodes in the _frame_.
    #
    def new_node( frame )
      key = frame.keys[frame.index]
      return if key.nil?

      cfg = frame.config
      name = frame.prefix.empty? ? key.to_s : frame.prefix + ".#{key}"
      Node.new(cfg, name, cfg[key], key)
    end

    # Structure describing a single iteration stack frame. A new stack frame
    # is created when we descend into a nested Configuration object.
    #
    Frame = Struct.new( :config, :prefix, :keys, :index )

    # This is a single node in a Configuration object. It corresponds to a
    # single configuration attribute.
    #
    Node = Struct.new( :config, :name, :desc, :key ) {
      def obj() config.__send__(key); end
      def config?() obj.kind_of? Configuration; end
    }

  end  # class Iterator
end  # module Loquacious
