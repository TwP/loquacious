
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
    obj.first.eql?('foo').should be_true
    obj.second.eql?('bar').should be_true
    obj.third.kind_of?(Loquacious::Undefined).should be_true
  end

  it 'should respond to any method' do
    @obj.first.kind_of?(Loquacious::Undefined).should be_true
    @obj.first = 'foo'
    @obj.first.eql?('foo').should be_true

    @obj.second = 'bar'
    @obj.second.eql?('bar').should be_true
  end

  it 'should deine attribute accessors when first used' do
    @obj.respond_to?(:foo).should be_false
    @obj.respond_to?(:foo=).should be_false

    @obj.foo
    @obj.respond_to?(:foo).should be_true
    @obj.respond_to?(:foo=).should be_true
  end

  it 'should provide a hash object for storing method descriptions' do
    h = @obj.__desc
    @obj.__desc.should equal(h)
  end

  it 'should allow attributes to be assigned hash values' do
    cfg = Loquacious::Configuration.new {
            hash({:one => 1})
          }
    cfg.hash.eql?({:one => 1}).should be_true
  end

  it 'should provide hash accessor notation for attributes' do
    cfg = Loquacious::Configuration.new {
            one   1
            two   2
            three 3
          }

    cfg['one'].eql?(1).should be_true
    cfg[:two].eql?(2).should be_true
    cfg['three'].eql?(3).should be_true

    cfg[:four].kind_of?(Loquacious::Undefined).should be_true
    cfg.four = 4
    cfg[:four].eql?(4).should be_true

    cfg[:five] = 5
    cfg.five.eql?(5).should be_true
    cfg[:five].eql?(5).should be_true
  end

  it 'should allow Kernel methods to be treated as configuration attributes' do
    cfg = Loquacious::Configuration.new {
            fork   'spoon knife spork'
            split  'join'
            raise  'double down'
            puts   'not what you think'
          }

    cfg['fork'].eql?('spoon knife spork').should be_true
    cfg['split'].eql?('join').should be_true
    cfg['raise'].eql?('double down').should be_true
    cfg['puts'].eql?('not what you think').should be_true

    cfg[:fork].eql?('spoon knife spork').should be_true
    cfg[:split].eql?('join').should be_true
    cfg[:raise].eql?('double down').should be_true
    cfg[:puts].eql?('not what you think').should be_true

    cfg.fork.eql?('spoon knife spork').should be_true
    cfg.split.eql?('join').should be_true
    cfg.raise.eql?('double down').should be_true
    cfg.puts.eql?('not what you think').should be_true
  end

  it 'should not be affected by loading other modules like timeout' do
    require 'timeout'
    Loquacious.remove :timeout
    cfg = Loquacious::Configuration.new {
            timeout  10
            foo      'bar'
            baz      'buz'
          }
    cfg.timeout.eql?(10).should be_true
    cfg.foo.eql?('bar').should be_true
    cfg.baz.eql?('buz').should be_true
  end

  it 'should evaluate Proc objects when fetching values' do
    obj = Loquacious::Configuration.new  {
            first    'foo'
            second   'bar'
          }

    obj.third = Proc.new { obj.first + obj.second }
    obj.third.eql?('foobar').should be_true

    obj.second = 'baz'
    obj.third.eql?('foobaz').should be_true

    obj.first = 'Hello '
    obj.second = 'World!'
    obj.third.eql?('Hello World!').should be_true
  end

  it 'should return a value when evaluating inside the DSL' do
    obj = Loquacious::Configuration.new  {
            first   'foo'
            second  {
              bar    nil
            }
          }

    obj.first.eql?('foo').should be_true
    obj.second.bar.eql?(nil).should be_true

    Loquacious::Configuration::DSL.evaluate(:config => obj) {
      first 'bar'
      second.bar 'no longer nil'
    }

    obj.first.eql?('bar').should be_true
    obj.second.bar.eql?('no longer nil').should be_true
  end

  it 'should not delete descriptions' do
    obj = Loquacious::Configuration.new  {
            first 'foo', :desc => 'the first value'

            desc 'the second value'
            second  {
              bar nil, :desc => 'time to go drinking'
            }
          }

    obj.first.eql?('foo').should be_true
    obj.second.bar.eql?(nil).should be_true

    obj.__desc[:first].should be == 'the first value'
    obj.__desc[:second].should be == 'the second value'
    obj.second.__desc[:bar].should be == 'time to go drinking'

    Loquacious::Configuration::DSL.evaluate(:config => obj) {
      first 'bar'
      second.bar 'no longer nil'
    }

    obj.first.eql?('bar').should be_true
    obj.second.bar.eql?('no longer nil').should be_true

    obj.__desc[:first].should be == 'the first value'
    obj.__desc[:second].should be == 'the second value'
    obj.second.__desc[:bar].should be == 'time to go drinking'
  end

  # -----------------------------------------------------------------------
  describe 'when merging' do
    before :each do
      Loquacious::Configuration.instance_variable_get(:@table).clear
    end

    it 'should merge the contents of another Configuration' do
      other = Loquacious::Configuration.new  {
                first   'foo', :desc => 'foo method'
                second  'bar', :desc => 'bar method'
              }

      @obj.first.kind_of?(Loquacious::Undefined).should be_true
      @obj.second.kind_of?(Loquacious::Undefined).should be_true
      @obj.__desc.should be == {:first => nil, :second => nil}

      @obj.merge! other
      @obj.first.eql?('foo').should be_true
      @obj.second.eql?('bar').should be_true
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

      @obj.first.eql?('foo').should be_true
      @obj.second.eql?('bar').should be_true
      @obj.third.question.eql?('?').should be_true
      @obj.third.answer.eql?(42).should be_true

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
      c.first.eql?('foo').should be_true
      c.second.bar.eql?(nil).should be_true
    end

    it 'does not overwrite existing configuration values' do
      c = Loquacious::Configuration.for('test') {
            first 1
            third 3
          }

      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar nil, :desc => 'time to go drinking'
        }
      }

      c.first.eql?(1).should be_true
      c.third.eql?(3).should be_true
      c.second.bar.eql?(nil).should be_true

      c.__desc[:first].should be == 'the first value'
      c.__desc[:second].should be == 'the second value'
      c.second.__desc[:bar].should be == 'time to go drinking'
      c.__desc[:third].should be_nil
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
            third 3
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

      c.first.eql?(1).should be_true
      c.third.eql?(3).should be_true
      c.second.bar.eql?('pub').should be_true
      c.second.baz.buz.eql?('random text').should be_true
      c.second.baz.boo.eql?('who').should be_true

      c.second.bar = Loquacious::Undefined.new('second.bar')
      c.second.bar.eql?('h-bar').should be_true

      c.__desc[:first].should be == 'the first value'
      c.__desc[:second].should be == 'the second value'
      c.second.__desc[:bar].should be == 'time to go drinking'
      c.second.__desc[:baz].should be == 'getting weird'
      c.second.baz.__desc[:buz].should be == 'post drinking feeling'
      c.second.baz.__desc[:boo].should be == 'no need to cry about it'
      c.__desc[:third].should be_nil
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
            third 3
          }

      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar 'h-bar', :desc => 'time to go drinking'
          baz nil, :desc => 'deprecated'
        }
      }

      c.second.baz.buz.eql?('random text').should be_true
      c.second.baz.boo.eql?('who').should be_true

      c.second.baz = Loquacious::Undefined.new('second.bar')
      c.second.baz.eql?(nil).should be_true
      c.second.__desc[:baz].should be == 'deprecated'
    end

    it 'properly handles Proc default values' do
      c = Loquacious::Configuration.for('test') {
            first 1
            second {
              bar 'pub'
            }
            third 3
          }

      Loquacious::Configuration.defaults_for('test') {
        first 'foo', :desc => 'the first value'
        desc 'the second value'
        second  {
          bar 'h-bar', :desc => 'time to go drinking'
          baz(Proc.new { c.third * 12 }, :desc => 'proc will be evaluated')
        }
      }

      c.second.baz.eql?(36).should be_true
      c.second.__desc[:baz].should be == 'proc will be evaluated'
    end
  end

  # -----------------------------------------------------------------------
  describe 'when converting to a hash' do
    it "should do so recursively" do
      c = Loquacious::Configuration.new {
        first 1, :desc => 'one is the loneliest number'
        second {
          bar 'pub', :desc => 'where the magic happens'
          desc 'overwrite me'
          baz {
            buz 'random text'
            boo 'who'
          }
        }
        third 3
      }
      c.to_hash.should == {
        :first => 1,
        :second => {
          :bar => 'pub',
          :baz => {
            :buz => 'random text',
            :boo => 'who'
          }
        },
        :third => 3
      }
    end

    it "just returns an empty hash for an empty configuration" do
      c = Loquacious::Configuration.new { }
      c.to_hash.should == {}
    end
  end

end

