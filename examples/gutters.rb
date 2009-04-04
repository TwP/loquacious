# Using Ruby heredocs for descriptions, the Loquacious configuration will
# strip out leading whitespace but preserve line breaks. Gutter lines can be
# used to mark where leading whitespace should be preserved. This is useful
# is you need to provide example code in your descriptions.

require 'loquacious'
include Loquacious

Configuration.for 'gutters' do
  desc <<-__
    The path to the log file to use. Defaults to log/\#{environment}.log
    (e.g. log/development.log or log/production.log).
    |
    |  config.log_path = File.join(ROOT, "log", "\#{environment}.log
    |
  __
  log_path

  log_level :warn, :desc => <<-__
    |The log level to use for the default Rails logger. In production mode,
    |this defaults to :info. In development mode, it defaults to :debug.
    |
    |  config.log_level = 'debug'
    |  config.log_level = :warn
    |
  __
end

help = Configuration.help_for 'gutters'
help.show :values => true
