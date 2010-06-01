
require File.expand_path('spec_helper', File.dirname(__FILE__))

describe String do

  it "reduces to a size by replacing characters from the middle" do
    "this is a longish string".reduce(10).should == "this...ing"
    "this is a longish string".reduce(15).should == "this i...string"
    "this is a longish string".reduce(24).should == "this is a longish string"

    "this is a longish string".reduce(10, '--').should == "this--ring"
  end

  it "indents by a given number of spaces" do
    "hello".indent(2).should == "  hello"
    "hello\nworld".indent(4).should == "    hello\n    world"
    "  a\nslightly\n longer\n   string\n".indent(2).should == "    a\n  slightly\n   longer\n     string\n  "
  end

  it "indents using a leader string" do
    "hello".indent("foo ").should == "foo hello"
    "hello\nworld".indent("...").should == "...hello\n...world"
    "  a\nslightly\n longer\n   string\n".indent("#").should == "#  a\n#slightly\n# longer\n#   string\n#"
  end

  it "removes a leading gutter from all lines" do
    str = "  | foo"
    result = str.gutter!
    result.should == " foo"
    result.should equal(str)

    str = <<-STRING
    | And this is where gutters really shine!
    | HERE DOCS!!
    ||they are the best
    |
    |    You can indent stuff nicely and all that
    |all done now
    STRING

    str.gutter!
    str.should == " And this is where gutters really shine!\n HERE DOCS!!\n|they are the best\n\n    You can indent stuff nicely and all that\nall done now\n"
  end

  it "creates a copy when removing a leading gutter" do
    str = "  | foo"
    result = str.gutter
    result.should == " foo"
    result.should_not equal(str)
  end
end

# EOF
