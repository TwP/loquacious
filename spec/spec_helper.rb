
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib loquacious]))

Spec::Runner.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

class File
  # call-seq:
  #    File.path_from_here { 'path/to/file' }
  #
  # Returns an expanded relative to the file from which the method was
  # called. This method wrappers up the following Ruby trick into a nice
  # method:
  #
  #   File.expand_path(File.join(File.dirname(__FILE__), 'path/to/file'))
  #
  # A block is needed in order to determine the binding of the caller so
  # that __FILE__ returns the correct value.
  #
  # ==== Example
  #
  #   File.path_from_here { 'path/to/file' }
  #   File.path_from_here { %w[.. .. up two directories] }
  #
  # The latter is the preferred method for calling as it allows File.join to
  # use its magic in determining the path separator for the system.
  #
  def self.path_from_here( &block )
    expand_path(join(dirname(eval('__FILE__',block.binding)), block.call))
  end
end

# EOF
