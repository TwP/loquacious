
require File.expand_path('../lib/loquacious', File.dirname(__FILE__))

RSpec.configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  Loquacious::Undefined.io = StringIO.new

  config.before :each do
    Loquacious::Undefined.io.clear

    table = Loquacious::Configuration.instance_variable_get(:@table)
    table.clear

    Loquacious.configuration_for('specs') do
      first   'foo', :desc => 'foo method'
      second  'bar', :desc => 'bar method'

      desc 'the third group'
      third {
        answer 42, :desc => 'life the universe and everything'
        question :symbol, :desc => 'perhaps you do not understand'
      }
    end
  end
end

class StringIO
  alias :_readline :readline
  def readline
    @pos ||= 0
    seek @pos
    line = _readline
    @pos = tell
    return line
  rescue EOFError
    nil
  end

  def clear
    @pos = 0
    seek 0
    truncate 0
  end

  def to_s
    @pos = tell
    seek 0
    str = read
    seek @pos
    return str
  end
end

