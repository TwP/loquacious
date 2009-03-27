
require 'pp'
require 'stringio'

class Loquacious::Configuration

  # Generate nicely formatted help messages for a configuration. The Help
  # class iterates over all the attributes in a configuration and outputs
  # the name, value, and description to an IO stream. The format of the
  # messages can be configured, and the description and/or value of the
  # attribute can be shown or hidden independently.
  #
  class Help

    # :stopdoc:
    @@defaults = {
      :io => $stdout,
      :name_leader => '  - '.freeze,
      :name_length => 20,
      :name_value_sep => ' => '.freeze,
      :desc_leader => ' '.freeze
    }.freeze

    class Error < StandardError; end
    # :startdoc:

    # Create a new Help instance for the given configuration where _config_
    # can be either a Configuration instance or a configuration name or
    # symbol. Several options can be provided to determine how the
    # configuration information will be printed to the IO stream.
    #
    #   :name_leader      String appearing before the attribute name
    #   :name_length      Maximum length for an attribute name
    #   :name_value_sep   String separating the attribute name from the value
    #   :desc_leader      String appearing before the description
    #   :io               The IO object where help will be written
    #
    # The description is printed before each attribute name and value on its
    # own line.
    #
    def initialize( config, opts = {} )
      opts = @@defaults.merge opts
      @config = config.kind_of?(::Loquacious::Configuration) ? config :
                ::Loquacious::Configuration.for(config)

      @io = opts[:io]
      @name_length = opts[:name_length].to_i
      @desc_leader = opts[:desc_leader]

      name_leader = opts[:name_leader]
      name_value_sep = opts[:name_value_sep]
      extra_length = name_leader.length + name_value_sep.length
      name_value_sep = name_value_sep.gsub('%', '%%')

      @value_length = 78 - @name_length - extra_length
      @value_leader = "\n" + ' '*(@name_length + extra_length)
      @format = "#{name_leader}%-#{@name_length}s#{name_value_sep}%s"
      @name_format = "#{name_leader}%s"

      @desc_leader.freeze
      @value_leader.freeze
      @format.freeze
      @name_format.freeze
    end

    # call-seq:
    #    show_attribute( name = nil, opts = {} )
    #
    # TODO: finish comments and docos
    #
    # show available attributes (with/without descriptions)
    # show current config
    # show everything
    #
    def show_attribute( name = nil, opts = {} )
      name, opts = nil, name if name.is_a?(Hash)
      opts = {
        :descriptions => true,
        :values => false
      }.merge!(opts)

      name = _normalize_attr(name)
      show_description = opts[:descriptions]
      show_value = opts[:values]

      Iterator.new(@config).each(name) do |node|
        _print_node(node, show_description, show_value)
      end
    end
    alias :show :show_attribute

    # Show all attributes for the configuration. The same options allowed by
    # the +show+ method are also supported by this method.
    #
    def show_all( opts = {} )
      show_attribute(nil, opts)
    end
    alias :show_attributes :show_all

    # Normalize the attribute _name_.
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

    # Format the attribute name, value, and description and print the
    # results. The value can be printed or not by setting the _show_value_
    # flag to either +true+ or +false+. The description can be printed or
    # not by setting the _show_description_ flag to either +true+ or
    # +false+.
    #
    def _print_node( node, show_description, show_value )
      desc = node.desc.to_s.dup
      show_description = false if desc.empty?
      @io.puts(desc.indent(@desc_leader)) if show_description
      @io.puts(_format_name(node, show_value))
      @io.puts if show_description
    end

    # Format the name of the attribute pointed at by the given _node_. If
    # the _show_value_ flag is set to +true+, then the attribute value will
    # also be included in the returned string.
    #
    def _format_name( node, show_value )
      name = node.name.reduce @name_length
      return @name_format % name if node.config? or !show_value

      sio = StringIO.new
      PP.pp(node.obj, sio, @value_length)
      sio.seek 0
      obj = sio.read.chomp.gsub("\n", @value_leader)
      @format % [name, obj]
    end

  end  # class Help
end  # module Loquacious

# EOF
