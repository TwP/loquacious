
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Loquacious::Configuration::Iterator do

  before(:each) do
    @config = Loquacious.configuration_for 'specs'
    @iterator = Loquacious::Configuration::Iterator.new(@config)
  end

  it 'should find a particular attribute' do
    node = @iterator.find 'first'
    node.name.should == 'first'
    node.key.should == :first
    node.desc.should == 'foo method'
    node.obj.should == 'foo'
    node.config?.should == false

    node = @iterator.find :third
    node.name.should == 'third'
    node.key.should == :third
    node.desc.should == 'the third group'
    node.config?.should == true

    node = @iterator.find('third.answer')
    node.name.should == 'third.answer'
    node.key.should == :answer
    node.desc.should == 'life the universe and everything'
    node.obj.should == 42
    node.config?.should == false
  end

  it 'should return nil for unknown attributes' do
    @iterator.find('last').should be_nil
    @iterator.find('last.first.none').should be_nil
    @iterator.find('third.none').should be_nil
    @iterator.find(:foo).should be_nil
  end

  it 'should iterate over all attributes' do
    ary = Array.new
    @iterator.each {|n| ary << n.name}

    ary.should == %w{first second third third.answer third.question}
  end

  it 'should iterate over nested attributes if given' do
    ary = Array.new
    @iterator.each('third') {|n| ary << n.name}
    ary.should == %w{third third.answer third.question}

    ary.clear
    @iterator.each('first') {|n| ary << n.name}
    ary.should == %w{first}

    ary.clear
    @iterator.each('not_here') {|n| ary << n.name}
    ary.should be_empty
  end
end

# EOF
