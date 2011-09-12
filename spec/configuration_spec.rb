
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Loquacious::Configuration do
  before(:each) do
    @obj = Loquacious::Configuration.new
  end

  it 'should initialize from a block' do
    obj = Loquacious::Configuration.new  {
            first    'foo'
            second   'bar'
          }
    obj.first.should be == 'foo'
    obj.second.should be == 'bar'
    obj.third.should be_nil
  end

  it 'should respond to any method' do
    @obj.first.should be_nil
    @obj.first = 'foo'
    @obj.first.should be == 'foo'

    @obj.second = 'bar'
    @obj.second.should be == 'bar'
  end

  it 'should deine attribute accessors when first used' do
    @obj.respond_to?(:foo).should be == false
    @obj.respond_to?(:foo=).should be == false

    @obj.foo
    @obj.respond_to?(:foo).should be == true
    @obj.respond_to?(:foo=).should be == true
  end

  it 'should provide a hash object for storing method descriptions' do
    h = @obj.__desc
    @obj.__desc.should equal(h)
  end

  it 'should allow attributes to be assigned hash values' do
    cfg = Loquacious::Configuration.new {
            hash({:one => 1})
          }
    cfg.hash.should be == {:one => 1}
  end

  it 'should provide hash accessor notation for attributes' do
    cfg = Loquacious::Configuration.new {
            one   1
            two   2
            three 3
          }

    cfg['one'].should be == 1
    cfg[:two].should be == 2
    cfg['three'].should be == 3

    cfg[:four].should be_nil
    cfg.four = 4
    cfg[:four].should be == 4

    cfg[:five] = 5
    cfg.five.should be == 5
    cfg[:five].should be == 5
  end

  it 'should allow Kernel methods to be treated as configuration attributes' do
    cfg = Loquacious::Configuration.new {
            fork   'spoon knife spork'
            split  'join'
            raise  'double down'
            puts   'not what you think'
          }

    cfg['fork'].should be == 'spoon knife spork'
    cfg['split'].should be == 'join'
    cfg['raise'].should be == 'double down'
    cfg['puts'].should be == 'not what you think'

    cfg[:fork].should be == 'spoon knife spork'
    cfg[:split].should be == 'join'
    cfg[:raise].should be == 'double down'
    cfg[:puts].should be == 'not what you think'

    cfg.fork.should be == 'spoon knife spork'
    cfg.split.should be == 'join'
    cfg.raise.should be == 'double down'
    cfg.puts.should be == 'not what you think'
  end

  it 'should not be affected by loading other modules like timeout' do
    require 'timeout'
    Loquacious.remove :timeout
    cfg = Loquacious::Configuration.new {
            timeout  10
            foo      'bar'
            baz      'buz'
          }
    cfg.timeout.should be == 10
    cfg.foo.should be == 'bar'
    cfg.baz.should be == 'buz'
  end

  it 'should evaluate Proc objects when fetching values' do
    obj = Loquacious::Configuration.new  {
            first    'foo'
            second   'bar'
          }

    obj.third = Proc.new { obj.first + obj.second }
    obj.third.should be == 'foobar'

    obj.second = 'baz'
    obj.third.should be == 'foobaz'

    obj.first = 'Hello '
    obj.second = 'World!'
    obj.third.should be == 'Hello World!'
  end

  it 'should return a value when evaluating inside the DSL' do
    obj = Loquacious::Configuration.new  {
            first   'foo'
            second  {
              bar    nil
            }
          }

    obj.first.should be == 'foo'
    obj.second.bar.should be_nil

    Loquacious::Configuration::DSL.evaluate(:config => obj) {
      first 'bar'
      second.bar 'no longer nil'
    }

    obj.first.should be == 'bar'
    obj.second.bar.should be == 'no longer nil'
  end

  it 'should not delete descriptions' do
    obj = Loquacious::Configuration.new  {
            first 'foo', :desc => 'the first value'

            desc 'the second value'
            second  {
              bar nil, :desc => 'time to go drinking'
            }
          }

    obj.first.should be == 'foo'
    obj.second.bar.should be_nil

    obj.__desc[:first].should be == 'the first value'
    obj.__desc[:second].should be == 'the second value'
    obj.second.__desc[:bar].should be == 'time to go drinking'

    Loquacious::Configuration::DSL.evaluate(:config => obj) {
      first 'bar'
      second.bar 'no longer nil'
    }

    obj.first.should be == 'bar'
    obj.second.bar.should be == 'no longer nil'

    obj.__desc[:first].should be == 'the first value'
    obj.__desc[:second].should be == 'the second value'
    obj.second.__desc[:bar].should be == 'time to go drinking'
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
      @obj.__desc.should be == {:first => nil, :second => nil}

      @obj.merge! other
      @obj.first.should be == 'foo'
      @obj.second.should be == 'bar'
      @obj.__desc.should be == {
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

      @obj.first.should be == 'foo'
      @obj.second.should be == 'bar'
      @obj.third.question.should be == '?'
      @obj.third.answer.should be == 42

      @obj.__desc.should be == {
        :first => 'foo method',
        :second => 'bar method',
        :third => 'the third group'
      }
      @obj.third.__desc.should be == {
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

      other.__desc[:first].should be == "This is the first thing we are defining in this config.\nIt has a multiline comment."
      other.__desc[:second].should be == "bar method\nalso a multiline comment"
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

      other.__desc[:first].should be == "  This is the first thing we are defining in this config.\n  It has a multiline comment."
      other.__desc[:second].should be == "This is a short explanation\n\nExample:\n  do this then that\n  followed by this line"
    end
  end

  # -----------------------------------------------------------------------
  describe 'when working with defaults' do
    before :each do
      Loquacious::Configuration.instance_variable_get(:@table).clear
    end

    it 'returns default values when no other value exists' do
      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar nil, :desc => 'time to go drinking'
        }
      }

      c = Loquacious::Configuration.for 'test'
      c.first.should be == 'foo'
      c.second.bar.should be_nil
    end

    it 'does not overwrite existing configuration values' do
      c = Loquacious::Configuration.for('test') {
            first 1
            thrid 3
          }

      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar nil, :desc => 'time to go drinking'
        }
      }

      c.first.should be == 1
      c.third.should be == 3
      c.second.bar.should be_nil

      c.__desc[:first].should be == 'the first value'
      c.__desc[:second].should be == 'the second value'
      c.second.__desc[:bar].should be == 'time to go drinking'
      c.__desc[:thrid].should be_nil
    end

    it 'does not overwrite nested configuration values' do
      c = Loquacious::Configuration.for('test') {
            first 1
            second {
              bar 'pub'
              baz {
                buz 'random text'
                boo 'who'
              }
            }
            thrid 3
          }

      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar 'h-bar', :desc => 'time to go drinking'
          desc 'getting weird'
          baz {
            buz 'buz', :desc => 'post drinking feeling'
            boo nil, :desc => 'no need to cry about it'
          }
        }
      }

      c.first.should be == 1
      c.third.should be == 3
      c.second.bar.should be == 'pub'
      c.second.baz.buz.should be == 'random text'
      c.second.baz.boo.should be == 'who'

      c.second.bar = Loquacious::Undefined.new('second.bar')
      c.second.bar.should be == 'h-bar'

      c.__desc[:first].should be == 'the first value'
      c.__desc[:second].should be == 'the second value'
      c.second.__desc[:bar].should be == 'time to go drinking'
      c.second.__desc[:baz].should be == 'getting weird'
      c.second.baz.__desc[:buz].should be == 'post drinking feeling'
      c.second.baz.__desc[:boo].should be == 'no need to cry about it'
      c.__desc[:thrid].should be_nil
    end

    it 'supports differing default type' do
      c = Loquacious::Configuration.for('test') {
            first 1
            second {
              bar 'pub'
              desc 'overwrite me'
              baz {
                buz 'random text'
                boo 'who'
              }
            }
            thrid 3
          }

      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar 'h-bar', :desc => 'time to go drinking'
          baz nil, :desc => 'deprecated'
        }
      }

      c.second.baz.buz.should be == 'random text'
      c.second.baz.boo.should be == 'who'

      c.second.baz = Loquacious::Undefined.new('second.bar')
      c.second.baz.should be_nil
      c.second.__desc[:baz].should be == 'deprecated'
    end

    it 'properly handles Proc default values' do
      c = Loquacious::Configuration.for('test') {
            first 1
            second {
              bar 'pub'
            }
            thrid 3
          }

      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar 'h-bar', :desc => 'time to go drinking'
          baz(Proc.new { c.third * 12 }, :desc => 'proc will be evaluated')
        }
      }

      c.second.baz.should be == 36
      c.second.__desc[:baz].should be == 'proc will be evaluated'
    end
  end

end

