
require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Loquacious::Configuration do
  before(:all) do
    @respond_to = Object.instance_method(:respond_to?)
  end

  before(:each) do
    @obj = Loquacious::Configuration.new
  end

  it 'should initialize from a block' do
    obj = Loquacious::Configuration.new  {
            first    'foo'
            second   'bar'
          }
    obj.first.should == 'foo'
    obj.second.should == 'bar'
    obj.third.should be_nil
  end

  it 'should respond to any method' do
    @obj.first.should be_nil
    @obj.first = 'foo'
    @obj.first.should == 'foo'

    @obj.second = 'bar'
    @obj.second.should == 'bar'
  end

  it 'should deine attribute accessors when first used' do
    m = @respond_to.bind(@obj)
    m.call(:foo).should == false
    m.call(:foo=).should == false

    @obj.foo
    m.call(:foo).should == true
    m.call(:foo=).should == true
  end

  it 'should provide a hash object for storing method descriptions' do
    h = @obj.__desc
    @obj.__desc.should equal(h)
  end

  it 'should allow attributes to be assigned hash values' do
    cfg = Loquacious::Configuration.new {
            hash({:one => 1})
          }
    cfg.hash.should == {:one => 1}
  end

  it 'should provide hash accessor notation for attributes' do
    cfg = Loquacious::Configuration.new {
            one   1
            two   2
            three 3
          }

    cfg['one'].should == 1
    cfg[:two].should == 2
    cfg['three'].should == 3

    cfg[:four].should be_nil
    cfg.four = 4
    cfg[:four].should == 4

    cfg[:five] = 5
    cfg.five.should == 5
    cfg[:five].should == 5
  end

  it 'should allow Kernel methods to be treated as configuration attributes' do
    cfg = Loquacious::Configuration.new {
            fork   'spoon knife spork'
            split  'join'
            raise  'double down'
            puts   'not what you think'
          }

    cfg['fork'].should == 'spoon knife spork'
    cfg['split'].should == 'join'
    cfg['raise'].should == 'double down'
    cfg['puts'].should == 'not what you think'

    cfg[:fork].should == 'spoon knife spork'
    cfg[:split].should == 'join'
    cfg[:raise].should == 'double down'
    cfg[:puts].should == 'not what you think'

    cfg.fork.should == 'spoon knife spork'
    cfg.split.should == 'join'
    cfg.raise.should == 'double down'
    cfg.puts.should == 'not what you think'
  end

  it 'should not be affected by loading other modules like timeout' do
    require 'timeout'
    cfg = Loquacious::Configuration.new {
            timeout  10
            foo      'bar'
            baz      'buz'
          }
    cfg.timeout.should == 10
    cfg.foo.should == 'bar'
    cfg.baz.should == 'buz'
  end

  it 'should evaluate Proc objects when fetching values' do
    obj = Loquacious::Configuration.new  {
            first    'foo'
            second   'bar'
          }

    obj.third = Proc.new { obj.first + obj.second }
    obj.third.should == 'foobar'

    obj.second = 'baz'
    obj.third.should == 'foobaz'

    obj.first = 'Hello '
    obj.second = 'World!'
    obj.third.should == 'Hello World!'
  end

  # -----------------------------------------------------------------------
  describe 'when merging' do

    it 'should merge the contents of another Configuration' do
      other = Loquacious::Configuration.new  {
                first   'foo', :desc => 'foo method'
                second  'bar', :desc => 'bar method'
              }

      @obj.first.should be_nil
      @obj.second.should be_nil
      @obj.__desc.should == {}

      @obj.merge! other
      @obj.first.should == 'foo'
      @obj.second.should == 'bar'
      @obj.__desc.should == {
        :first => 'foo method',
        :second => 'bar method'
      }
    end

    it 'should recursively merge nested Configuration' do
      other = Loquacious::Configuration.new  {
        first   'foo', :desc => 'foo method'
        second  'bar', :desc => 'bar method'

        desc 'the third group'
        third {
          answer 42, :desc => 'life the universe and everything'
        }
      }

      @obj = Loquacious::Configuration.new  {
        third {
          question '?', :desc => 'perhaps you do not understand'
        }
      }

      @obj.merge! other

      @obj.first.should == 'foo'
      @obj.second.should == 'bar'
      @obj.third.question.should == '?'
      @obj.third.answer.should == 42

      @obj.__desc.should == {
        :first => 'foo method',
        :second => 'bar method',
        :third => 'the third group'
      }
      @obj.third.__desc.should == {
        :question => 'perhaps you do not understand',
        :answer => 'life the universe and everything'
      }
    end

    it 'should raise an error when merging with an unknown object' do
      lambda {@obj.merge! 'foo'}.
          should raise_error(Loquacious::Configuration::Error, "can only merge another Configuration")
    end
  end

  # -----------------------------------------------------------------------
  describe 'when working with descriptions' do

    it 'should consume leading whitespace' do
      other = Loquacious::Configuration.new  {
        desc <<-STR
          This is the first thing we are defining in this config.
          It has a multiline comment.
        STR
        first   'foo'
        second  'bar', :desc => "bar method\n  also a multiline comment"
      }

      other.__desc[:first].should == "This is the first thing we are defining in this config.\nIt has a multiline comment."
      other.__desc[:second].should == "bar method\nalso a multiline comment"
    end

    it 'should leave whitespace after a gutter marker' do
      other = Loquacious::Configuration.new  {
        desc <<-STR
        |  This is the first thing we are defining in this config.
        |  It has a multiline comment.
        STR
        first   'foo'

        desc <<-DESC
          This is a short explanation

          Example:
          |  do this then that
          |  followed by this line
        DESC
        second  'bar'
      }

      other.__desc[:first].should == "  This is the first thing we are defining in this config.\n  It has a multiline comment."
      other.__desc[:second].should == "This is a short explanation\n\nExample:\n  do this then that\n  followed by this line"
    end

  end
end

# EOF
