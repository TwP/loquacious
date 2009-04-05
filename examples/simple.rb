# A simple example that configures three options (a b c) along with
# descriptions for each option. The descriptions along with the
# values for the configuration options are printed to the terminal.

require 'loquacious'
include Loquacious

Configuration.for(:simple) {
  desc 'Your first configuration option'
  a "value for 'a'"

  desc 'To be or not to be'
  b "William Shakespeare"

  desc 'The underpinings of Ruby'
  c 42
}

help = Configuration.help_for :simple
help.show :values => true
