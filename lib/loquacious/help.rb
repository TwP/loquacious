
require 'pp'
require 'stringio'

module Loquacious

  #
  #
  class Help

    # :stopdoc:
    class Error < StandardError; end
    NAME_LENGTH = 20
    DESC_LENGTH = 78 - 6 - NAME_LENGTH
    SEP = "\n" + ' '*(NAME_LENGTH+6)
    FMT = "- %-#{NAME_LENGTH}s => %s"
    NAME_FMT = "- %-#{NAME_LENGTH}s"
    DESC_SEP = "\n     "
    # :startdoc:

    #
    #
    def initialize( config, io = $stdout )
      @io = io
      config = config.kind_of?(::Loquacious::Configuration) ? config :
               ::Loquacious::Configuration.for(config)
      @iterator = Iterator.new config
    end

    attr_reader :iterator, :io


    # call-seq:
    #    show_attribute( name = nil, out = io, opts = {} )
    #
    # show available attributes (with/without dscriptions)
    # show current config
    # show everything
    #
    def show_attribute( *args )
      opts = {
        :description => true,
        :value => false
      }.merge!(args.last.is_a?(Hash) ? args.pop : Hash.new)

      name, out = args
      name = _normalize_attr(name)
      out ||= io

      iterator.each(name) do |node|
        _print_node(node, out, opts)
      end
    end
    alias :show_attributes :show_attribute

    #
    #
    def _normalize_attr( name )
      case name
      when String, nil; name
      when Symbol; name.to_s
      when Array;  name.join('.')
      else
        raise Error, "cannot convert #{name.inspect} into an attribute identifier"
      end
    end

    def _print_node( node, out, opts )
      out.puts(_format_name(node, opts[:value]))

      desc = node.desc.to_s.dup
      return if desc.empty? or !opts[:description]

      desc.gsub!("\n", DESC_SEP)
      desc.insert(0, DESC_SEP.tr("\n", ''))
      out.puts(desc)
      out.puts
    end

    def _format_name( node, show_value )
      name = node.name.reduce NAME_LENGTH
      return NAME_FMT % name if node.config? or !show_value

      sio = StringIO.new
      PP.pp(node.obj, sio, DESC_LENGTH)
      sio.seek 0
      obj = sio.read.chomp.gsub("\n", SEP)
      FMT % [name, obj]
    end

  end  # class Help
end  # module Loquacious

class String

  # call-seq:
  #    reduce( width, ellipses = '...' )    #=> string
  #
  # Reduce the size of the current string to the given _width_ by removing
  # characters from the middle of the string and replacing them with
  # _ellipses_. If the _width_ is greater than the length of the string, the
  # string is returned unchanged. If the _width_ is less than the length of
  # the _ellipses_, then the _ellipses_ are returned.
  #
  def reduce( width, ellipses = '...')
    raise ArgumentError, "width cannot be negative: #{width}" if width < 0

    return self if length <= width

    remove = length - width + ellipses.length
    return ellipses.dup if remove >= length

    left_end = (length + 1 - remove) / 2
    right_start = left_end + remove

    left = self[0,left_end]
    right = self[right_start,length-right_start]

    left << ellipses << right
  end
end

# EOF
