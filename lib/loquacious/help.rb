
module Loquacious

  #
  #
  class Help

    # :stopdoc:
    class Error < StandardError; end
    # :startdoc:

    def initialize( cfg )
      @cfg = cfg
    end

    attr_reader :cfg

    def describe( var = nil )
      var = case var
        when nil; var
        when String; var.split('.').map! {|x| x.to_sym}
        when Array;  var.map! {|x| x.to_sym}
        else raise 'what again?' end

      return describe_node(cfg, var) if var

      describe_all cfg
    end

    private

    def describe_node( cfg, var )
      h = Hash.new

      name = var.join('.')
      n = node_for(cfg, var)
      h[name] = n.desc

      if n.config?
        h.merge! describe_all(n.obj, name)
      end

      return h
    rescue Error
      raise Error, "unknown configuration attribute '#{name}'"
    end

    def describe_all( cfg, pre = nil )
      h = Hash.new

      cfg.__desc.keys.each do |key|
        n = Node.new key, cfg[key], cfg
        name = [pre, key].compact.join('.')
        h[name] = n.desc

        if n.config?
          h.merge! describe_all(n.obj, name)
        end
      end

      return h
    end

    def node_for( cfg, ary )
      ary = ary.dup
      key = ary.pop
      cfg = ary.inject(cfg) do |c,k|
        raise Error unless c.__desc.has_key? k
        c.__send__(k)
      end
      raise Error unless cfg.__desc.has_key? key

      Node.new key, cfg[key], cfg
    end

    Node = Struct.new( :key, :desc, :cfg ) {
      def obj() @obj ||= cfg.__send__(key); end
      def config?() obj.kind_of? Configuration; end
    }

  end  # class Help
end  # module Loquacious

# EOF
