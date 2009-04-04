# Here we show how to used nested configuration options by taking a subset
# of some common Rails configuration options. Also, descriptions can be give
# before the option or they can be given inline using Ruby hash notation. If
# both are present, then the inline description takes precedence.
#
# Multiline descriptions are provided using Ruby heredocs. Leading
# whitespace is stripped and line breaks are preserved when descriptions
# are printed using the help object.

require 'loquacious'
include Loquacious

Configuration.for 'nested' do
  root_path '.', :desc => "The application's base directory."

  desc "Configuration options for ActiveRecord::Base."
  active_record {
    desc <<-__
      Determines whether to use ANSI codes to colorize the logging statements committed
      by the connection adapter. These colors make it much easier to overview things
      during debugging (when used through a reader like +tail+ and on a black background),
      but may complicate matters if you use software like syslog. This is true, by default.
    __
    colorize_logging true

    desc <<-__
      Determines whether to use Time.local (using :local) or Time.utc (using :utc)
      when pulling dates and times from the database. This is set to :local by default.
    __
    default_timezone :local
  }

  desc <<-__
    The log level to use for the default Rails logger. In production mode,
    this defaults to :info. In development mode, it defaults to :debug.
  __
  log_level :info

  desc <<-__
    The path to the log file to use. Defaults to log/\#{environment}.log
    (e.g. log/development.log or log/production.log).
  __
  log_path 'log/development.log'
end

help = Configuration.help_for 'nested'
help.show :values => true
