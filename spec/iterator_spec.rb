
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Loquacious::Configuration::Iterator do

  before(:each) do
    @config = Loquacious.configuration_for 'specs'
    @iterator = Loquacious::Configuration::Iterator.new(@config)
  end

  it 'should find a particular attribute' do
    node = @iterator.find 'first'
    node.name.should be == 'first'
    node.key.should be == :first
    node.desc.should be == 'foo method'
    node.obj.should be == 'foo'
    node.config?.should be == false

    node = @iterator.find :third
    node.name.should be == 'third'
    node.key.should be == :third
    node.desc.should be == 'the third group'
    node.config?.should be == true

    node = @iterator.find('third.answer')
    node.name.should be == 'third.answer'
    node.key.should be == :answer
    node.desc.should be == 'life the universe and everything'
    node.obj.should be == 42
    node.config?.should be == false
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

    ary.should be == %w{first second third third.answer third.question}
  end

  it 'should iterate over nested attributes if given' do
    ary = Array.new
    @iterator.each('third') {|n| ary << n.name}
    ary.should be == %w{third third.answer third.question}

    ary.clear
    @iterator.each('first') {|n| ary << n.name}
    ary.should be == %w{first}

    ary.clear
    @iterator.each('not_here') {|n| ary << n.name}
    ary.should be_empty
  end

  it 'should ignore undefined nodes' do
    @config.does_not_exist.foo  # this creates a Loquacious::Undefined node
    @config.does_not_exist.kind_of?(::Loquacious::Undefined).should be_true

    ary = Array.new
    @iterator.each {|n| ary << n.name}
    ary.should be == %w{first second third third.answer third.question}
  end
end

# EOF
