
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Loquacious::Configuration::Help do

  before :all do
    @sio = StringIO.new
  end

  before :each do
    @config = Loquacious.configuration_for 'specs'
    @help = Loquacious::Configuration::Help.new 'specs', :io => @sio
    @sio.clear
  end

  it "returns a help object by name" do
    help = Loquacious::Configuration::Help.new 'specs'
    config = help.instance_variable_get(:@config)
    config.should equal(@config)
  end

  it "returns a help object for a configuration" do
    help = Loquacious::Configuration::Help.new @config
    config = help.instance_variable_get(:@config)
    config.should equal(@config)
  end

  it "raises an error for invalid attribute names" do
    lambda {@help.show(42)}.should raise_error(
        Loquacious::Configuration::Help::Error,
        "cannot convert 42 into an attribute identifier"
    )
  end

  it "prints out all attribues" do
    str = <<-OUTPUT
    | foo method
    |  - first
    |
    | bar method
    |  - second
    |
    | the third group
    |  - third
    |
    | life the universe and everything
    |  - third.answer
    |
    | perhaps you do not understand
    |  - third.question
    |
    OUTPUT

    @help.show_all
    @sio.to_s.should be == str.gutter!
  end

  it "prints out a specific attribute" do
    str = <<-OUTPUT
    | bar method
    |  - second
    |
    OUTPUT
    @help.show_attribute :second
    @sio.to_s.should be == str.gutter!
  end

  it "properly parses nested attributes" do
    str = <<-OUTPUT
    | the third group
    |  - third
    |
    | life the universe and everything
    |  - third.answer
    |
    | perhaps you do not understand
    |  - third.question
    |
    OUTPUT
    @help.show_attribute 'third'
    @sio.to_s.should be == str.gutter!

    @sio.clear
    str = <<-OUTPUT
    | perhaps you do not understand
    |  - third.question
    |
    OUTPUT
    @help.show_attribute %w[third question]
    @sio.to_s.should be == str.gutter!

    @sio.clear
    str = <<-OUTPUT
    | life the universe and everything
    |  - third.answer
    |
    OUTPUT
    @help.show_attribute 'third.answer'
    @sio.to_s.should be == str.gutter!
  end

  it "hides nesting attributes" do
    help = Loquacious::Configuration::Help.new @config, :nesting_nodes => false, :io => @sio

    str = <<-OUTPUT
    | foo method
    |  - first
    |
    | bar method
    |  - second
    |
    | life the universe and everything
    |  - third.answer
    |
    | perhaps you do not understand
    |  - third.question
    |
    OUTPUT

    help.show_all
    @sio.to_s.should be == str.gutter!

    @sio.clear
    str = <<-OUTPUT
    | life the universe and everything
    |  - third.answer
    |
    | perhaps you do not understand
    |  - third.question
    |
    OUTPUT
    help.show_attribute 'third'
    @sio.to_s.should be == str.gutter!

    @sio.clear
  end

  it "preserves indentation for descriptions" do
    Loquacious.configuration_for('specs') do
      desc <<-DESC
      This is a multiline description that has an example.
      |
      |   foo = %w[one two three]
      |
      See, the example is right above this line.
      Hope it was instructive.
      DESC
      fourth 'the fourth value'
    end

    str = <<-OUTPUT
    | This is a multiline description that has an example.
    | 
    |    foo = %w[one two three]
    | 
    | See, the example is right above this line.
    | Hope it was instructive.
    |  - fourth
    |
    OUTPUT
    @help.show_attribute 'fourth'
    @sio.to_s.should be == str.gutter!
  end

  it "pretty prints values" do
    str = <<-OUTPUT
    | foo method
    |  - first          => "foo"
    |
    | bar method
    |  - second         => "bar"
    |
    | the third group
    |  - third
    |
    | life the universe and everything
    |  - third.answer   => 42
    |
    | perhaps you do not understand
    |  - third.question => :symbol
    |
    OUTPUT
    @help.show :values => true
    @sio.to_s.should be == str.gutter!
  end

  it "closely packs attributes when descriptions are omitted" do
    str = <<-OUTPUT
    |  - first          => "foo"
    |  - second         => "bar"
    |  - third
    |  - third.answer   => 42
    |  - third.question => :symbol
    OUTPUT
    @help.show_all :values => true, :descriptions => false
    @sio.to_s.should be == str.gutter!
  end

  it "automatically picks up changes to the configuration" do
    Loquacious.configuration_for('specs') do
      fifth 'foo', :desc => 'the fifth configuration setting'
    end

    str = <<-OUTPUT
    | the fifth configuration setting
    |  - fifth
    |
    OUTPUT
    @help.show_attribute 'fifth'
    @sio.to_s.should be == str.gutter!
  end

  it "uses a custom name leader" do
    help = Loquacious.help_for 'specs', :io => @sio, :name_leader => ' ## '
    str = <<-OUTPUT
    | foo method
    | ## first
    |
    | bar method
    | ## second
    |
    | the third group
    | ## third
    |
    | life the universe and everything
    | ## third.answer
    |
    | perhaps you do not understand
    | ## third.question
    |
    OUTPUT
    help.show_all
    @sio.to_s.should be == str.gutter!

    @sio.clear
    str = <<-OUTPUT
    | ## first          => "foo"
    | ## second         => "bar"
    | ## third
    | ## third.answer   => 42
    | ## third.question => :symbol
    OUTPUT
    help.show_all :values => true, :descriptions => false
    @sio.to_s.should be == str.gutter!
  end

  it "uses a custom name length" do
    help = Loquacious.help_for 'specs', :io => @sio, :name_length => 10
    str = <<-OUTPUT
    | foo method
    |  - first
    |
    | bar method
    |  - second
    |
    | the third group
    |  - third
    |
    | life the universe and everything
    |  - thir...wer
    |
    | perhaps you do not understand
    |  - thir...ion
    |
    OUTPUT
    help.show_all
    @sio.to_s.should be == str.gutter!

    @sio.clear
    str = <<-OUTPUT
    |  - first      => "foo"
    |  - second     => "bar"
    |  - third
    |  - thir...wer => 42
    |  - thir...ion => :symbol
    OUTPUT
    help.show_all :values => true, :descriptions => false
    @sio.to_s.should be == str.gutter!
  end

  it "uses a custom name/value separator" do
    help = Loquacious.help_for 'specs', :io => @sio, :name_value_sep => ' :: '
    str = <<-OUTPUT
    | foo method
    |  - first          :: "foo"
    |
    | bar method
    |  - second         :: "bar"
    |
    | the third group
    |  - third
    |
    | life the universe and everything
    |  - third.answer   :: 42
    |
    | perhaps you do not understand
    |  - third.question :: :symbol
    |
    OUTPUT
    help.show_all :values => true
    @sio.to_s.should be == str.gutter!

    @sio.clear
    str = <<-OUTPUT
    |  - first          :: "foo"
    |  - second         :: "bar"
    |  - third
    |  - third.answer   :: 42
    |  - third.question :: :symbol
    OUTPUT
    help.show_all :values => true, :descriptions => false
    @sio.to_s.should be == str.gutter!
  end

  it "uses a custom description leader" do
    Loquacious.configuration_for('specs') do
      desc <<-DESC
      This is a multiline description that has an example.
      |
      |   foo = %w[one two three]
      |
      See, the example is right above this line.
      Hope it was instructive.
      DESC
      fourth 'the fourth value'
    end

    help = Loquacious.help_for 'specs', :io => @sio, :desc_leader => '~'
    str = <<-OUTPUT
    |~foo method
    |  - first          => "foo"
    |
    |~This is a multiline description that has an example.
    |~
    |~   foo = %w[one two three]
    |~
    |~See, the example is right above this line.
    |~Hope it was instructive.
    |  - fourth         => "the fourth value"
    |
    |~bar method
    |  - second         => "bar"
    |
    |~the third group
    |  - third
    |
    |~life the universe and everything
    |  - third.answer   => 42
    |
    |~perhaps you do not understand
    |  - third.question => :symbol
    |
    OUTPUT
    help.show_all :values => true
    @sio.to_s.should be == str.gutter!
  end
end

# EOF
