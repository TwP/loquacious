
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

  it 'should consume leading whitespace in descriptions' do
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
end

# EOF
