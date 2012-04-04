
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
      :name_length => 0,
      :name_value_sep => ' => '.freeze,
      :desc_leader => ' '.freeze,
      :nesting_nodes => true,
      :colorize => false,
      :colors => {
        :name => :white,
        :value => :cyan,
        :description => :green,
        :leader => :yellow
      }.freeze
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
    #   :nesting_nodes    Flag to enable or disable output of nesting nodes
    #                     (this does not affect display of attributes
    #                     contained by the nesting nodes)
    #   :colorize         Flag to colorize the output or not
    #   :colors           Hash of colors for the name, value, description
    #       :name           Name color
    #       :value          Value color
    #       :description    Description color
    #       :leader         Leader and spacer color
    #
    # The description is printed before each attribute name and value on its
    # own line.
    #
    def initialize( config, opts = {} )
      opts = @@defaults.merge opts
      @config = config.kind_of?(::Loquacious::Configuration) ? config :
                ::Loquacious::Configuration.for(config)

      @io = opts[:io]
      @name_length = Integer(opts[:name_length])
      @desc_leader = opts[:desc_leader]
      @nesting_nodes = opts[:nesting_nodes]
      @colorize = opts[:colorize]
      @colors = opts[:colors]

      unless @name_length > 0
        Iterator.new(@config).each do |node|
          length = node.name.length
          @name_length = length if length > @name_length
        end
      end

      name_leader = opts[:name_leader]
      name_value_sep = opts[:name_value_sep]
      extra_length = name_leader.length + name_value_sep.length
      name_value_sep = name_value_sep.gsub('%', '%%')

      @value_length = 78 - @name_length - extra_length
      @value_leader = "\n" + ' '*(@name_length + extra_length)
      @format = "#{name_leader}%-#{@name_length}s#{name_value_sep}%s"
      @name_format = "#{name_leader}%s"

      if colorize?
        @desc_leader = self.__send__(@colors[:leader], @desc_leader)
        name_leader = self.__send__(@colors[:leader], name_leader)
        name_value_sep = self.__send__(@colors[:leader], name_value_sep)

        @format = name_leader.dup
        @format << self.__send__(@colors[:name], "%-#{@name_length}s")
        @format << name_value_sep.dup
        @format << self.__send__(@colors[:value], "%s")

        @name_format = name_leader.dup
        @name_format << self.__send__(@colors[:name], "%s")
      end

      @desc_leader.freeze
      @value_leader.freeze
      @format.freeze
      @name_format.freeze
    end

    # Returns +true+ if the help instance is configured to colorize the
    # output messages. Returns +false+ otherwise.
    #
    def colorize?
      @colorize
    end

    # Returns +true+ if the help instance is configured to show nesting
    # configuration nodes when iterating over the attributes. This only
    # prevents the nesting node name from being displayed. The attributes
    # nested under the node are still displayed regardless of this setting.
    #
    def show_nesting_nodes?
      @nesting_nodes
    end

    # call-seq:
    #    show_attribute( name = nil, opts = {} )
    #
    # Use this method to show the description for a single attribute or for
    # all the attributes if no _name_ is given. The options allow you to
    # show the values along with the attributes and to hide the descriptions
    # (if all you want to see are the values).
    #
    #    :descriptions => true to show descriptions and false to hide them
    #    :values       => true to show values and false to hide them
    #
    def show_attribute( name = nil, opts = {} )
      name, opts = nil, name if name.is_a?(Hash)
      opts = {
        :descriptions => true,
        :values => false
      }.merge!(opts)

      rgxp = Regexp.new(normalize_attr(name))
      show_description = opts[:descriptions]
      show_value = opts[:values]

      Iterator.new(@config).each do |node|
        next unless rgxp =~ node.name
        next if !show_nesting_nodes? and node.config?
        print_node(node, show_description, show_value)
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
    def normalize_attr( name )
      case name
      when String, nil; name.to_s
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
    def print_node( node, show_description, show_value )
      desc = node.desc.to_s.dup
      show_description = false if desc.empty?

      if show_description
        if colorize?
          desc = desc.gsub(%r/([^\n]+)/,
                           self.__send__(@colors[:description], '\1'))
        end
        @io.puts(desc.indent(@desc_leader))
      end

      @io.puts(format_name(node, show_value))
      @io.puts if show_description
    end

    # Format the name of the attribute pointed at by the given _node_. If
    # the _show_value_ flag is set to +true+, then the attribute value will
    # also be included in the returned string.
    #
    def format_name( node, show_value )
      name = node.name.reduce @name_length
      return @name_format % name if node.config? or !show_value

      sio = StringIO.new
      PP.pp(node.obj, sio, @value_length)
      sio.seek 0
      obj = sio.read.chomp.gsub("\n", @value_leader)
      @format % [name, obj]
    end

    [ [ :clear        ,   0 ],
      [ :reset        ,   0 ],     # synonym for :clear
      [ :bold         ,   1 ],
      [ :dark         ,   2 ],
      [ :italic       ,   3 ],     # not widely implemented
      [ :underline    ,   4 ],
      [ :underscore   ,   4 ],     # synonym for :underline
      [ :blink        ,   5 ],
      [ :rapid_blink  ,   6 ],     # not widely implemented
      [ :negative     ,   7 ],     # no reverse because of String#reverse
      [ :concealed    ,   8 ],
      [ :strikethrough,   9 ],     # not widely implemented
      [ :black        ,  30 ],
      [ :red          ,  31 ],
      [ :green        ,  32 ],
      [ :yellow       ,  33 ],
      [ :blue         ,  34 ],
      [ :magenta      ,  35 ],
      [ :cyan         ,  36 ],
      [ :white        ,  37 ],
      [ :on_black     ,  40 ],
      [ :on_red       ,  41 ],
      [ :on_green     ,  42 ],
      [ :on_yellow    ,  43 ],
      [ :on_blue      ,  44 ],
      [ :on_magenta   ,  45 ],
      [ :on_cyan      ,  46 ],
      [ :on_white     ,  47 ] ].each do |name,code|

      class_eval <<-CODE
        def #{name.to_s}( str )
          "\e[#{code}m\#{str}\e[0m"
        end
      CODE
    end

  end  # class Help
end  # module Loquacious

